const mysql = require('mysql2/promise');

async function main() {
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '1q2w3e4r5tA',
      database: 'scantek_db'
    });

    console.log("Connected to the DB.");

    await connection.execute(`
      ALTER TABLE bans MODIFY COLUMN reason_category ENUM(
        'aggressive_behavior','intoxication','property_damage','harassment',
        'underage','drug_use','trespassing','other',
        'misconduct','security_violation','unauthorized_access','suspicious_behaviour'
      ) NOT NULL
    `);

    console.log("Successfully updated bans table ENUM.");
    await connection.end();
  } catch (error) {
    console.error("Error connecting to the DB / altering table:", error);
  }
}

main();
