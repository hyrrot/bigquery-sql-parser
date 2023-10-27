const fs = require('fs');
const peggy = require("peggy");

const grammar = fs.readFileSync("src/metalang.pegjs", "utf8");
const parser = peggy.generate(grammar);
const text = fs.readFileSync("src/metalang.mt", "utf8");

console.log(parser.parse(text));