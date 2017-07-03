const mssql = require('mssql');

const argv = require('yargs')
  .option('server', {
    describe: 'server hostname',
    demandOption: true,
  })
  .option('username', {
    describe: 'database username',
    demandOption: true,
  })
  .option('password', {
    describe: 'database password',
    demandOption: true,
  })
  .option('database', {
    describe: 'database name',
    demandOption: true,
  })
  .option('queries', {
    describe: 'json array of queries, optionally base64 encoded',
    coerce: (arg) => {
      const json = arg[0] == '[' || Buffer.from(arg, 'base64');
      return JSON.parse(json);
    }
  })
  .option('users', {
    describe: 'json map of username/password, optionally base64 encoded',
    coerce: (arg) => {
      const json = arg[0] == '[' || Buffer.from(arg, 'base64');
      return JSON.parse(json);
    }
  })
  .argv;

if ((!argv.users && !argv.queries) || (argv.users && argv.queries)) {
  console.warn("Must provide either --users or --queries but not both");
  process.exit(1);
}

const queries = argv.queries || buildUserQueries(argv.users);

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
      .then(() => processQueries(tx, queries))
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

function buildUserQueries(usersAndPasswords) {
  return Object.keys(usersAndPasswords).map((username) => `
  IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '${username}')
    ALTER USER ${username} WITH PASSWORD = '${usersAndPasswords[username]}';
ELSE
    CREATE USER ${username} WITH PASSWORD = '${usersAndPasswords[username]}';
`);
}
