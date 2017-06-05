const mssql = require('mssql');

const argv = require('yargs')
  .option('server', {
    describe: 'server hostname'
  })
  .option('username', {
    describe: 'database username'
  })
  .option('password', {
    describe: 'database password'
  })
  .option('database', {
    describe: 'database name'
  })
  .option('queries', {
    describe: 'json array of queries, optionally base64 encoded',
    coerce: (arg) => {
      const json = arg[0] == '[' || Buffer.from(arg, 'base64');
      return JSON.parse(json);
    }
  })
  .demandOption(['server', 'username', 'password', 'database', 'queries'])
  .argv;

console.log(
  "Connecting to %s@%s/%s",
  argv.username, argv.server, argv.database
);
mssql.connect({
  server: argv.server,
  user: argv.username,
  password: argv.password,
  database: argv.database,
  connectionTimeout: 3000,
  options: { encrypt: true },
  pool: { max: 1 }
})
  .then((db) => {
    console.log("Connected");
    const tx = db.transaction();
    return tx.begin()
      .then(() => processQueries(tx, argv.queries))
      .then(() => tx.commit())
      .then(() => db.close())
      .catch((err) => {
        console.error("FAILED", err);
        db.close();
        process.exit(1);
      });
  })

function processQueries(tx, queries) {
  const [query, ...remainingQueries] = queries;
  console.log("Executing query `%s`", query);
  return tx.request().query(query).then((result) => {
    console.log("Success", result);
    if (remainingQueries.length) {
      return processQueries(tx, remainingQueries);
    }
    return null;
  });
}
