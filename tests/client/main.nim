import solana
import yaml
import std/[json, os]

proc getConfig*(): JsonNode =
  yaml.loadToJson(readFile(expandTilde("~/.config/solana/cli/config.yml")))[0]

proc getRpcUrl*(): string =
  getConfig()["json_rpc_url"].to(string)

proc createKeypairFromFile*(path: string): Keypair =
  let j = json.parseFile(path)
  Keypair.fromSecretKey(j.to(seq[byte]))

proc getPayer*(): Keypair =
  let keypath = getConfig()["keypair_path"].to(string)
  createKeypairFromFile(keypath)

echo getPayer()
echo getRpcUrl()

# Establish connection
let cl = newClient(getRpcUrl())
echo "version: ", cl.getVersion()

# Establish payer
let payer = getPayer()

echo "bh: ", cl.getRecentBlockhash()
echo "bal: ", cl.getBalance(getPayer().publicKey)

echo cl.getAccountInfo(payer.publicKey)
