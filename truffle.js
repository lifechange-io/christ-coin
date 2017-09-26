module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      gas: 4612388
    },
    live: {
      from: "0xb34a722A46Ef57c7AF0567b07Aa304097Da34bec",
      network_id: 1,
      gas: 6012388
    }
  }
};
