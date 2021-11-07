import json
import nimpy

type
  PublicKey* = ref object
    impl: PyObject

  Keypair* = ref object
    impl: PyObject

  Client* = ref object
    impl: PyObject

  TransactionInstruction* = ref object
    impl: PyObject

let solpk = pyImport("solana.publickey")
let solkp = pyImport("solana.keypair")
let solapi = pyImport("solana.rpc.api")

proc createWithSeed*(p: typedesc[PublicKey], fromPk: PublicKey, seed: string, programId: PublicKey): PublicKey =
  PublicKey(impl: solpk.PublicKey.create_with_seed(fromPk.impl, seed, programId.impl))

proc createKeypairFromSeed(seed: openarray[byte]): Keypair =
  Keypair(impl: solkp.getAttr("Keypair").from_seed(seed))

proc fromSeed*(p: typedesc[Keypair], seed: openarray[byte]): Keypair {.inline.} =
  createKeypairFromSeed(seed)

proc fromSecretKey*(p: typedesc[Keypair], key: openarray[byte]): Keypair =
  Keypair.fromSeed(key[0 .. 31])

proc newKeypair*(): Keypair =
  Keypair(impl: solkp.callMethod("Keypair"))

proc publicKey*(k: Keypair): PublicKey =
  PublicKey(impl: k.impl.public_key)

proc `$`*(k: PublicKey): string = $k.impl
proc `$`*(k: Keypair): string = $k.publicKey


proc newClient*(endpoint = "", commitment = ""): Client =
  Client(impl: solapi.callMethod("Client", endpoint, commitment))

proc getVersion*(c: Client): JsonNode =
  c.impl.callMethod(JsonNode, "get_version")["result"]

proc getRecentBlockhash*(c: Client): JsonNode =
  c.impl.callMethod(JsonNode, "get_recent_blockhash")["result"]

proc getBalance*(c: Client, pk: PublicKey, commitment = ""): JsonNode =
  c.impl.callMethod(JsonNode, "get_balance", pk.impl, commitment)["result"]

proc requestAirdrop*(c: Client, pk: PublicKey, lamports: int, commitment = ""): string =
  c.impl.callMethod(JsonNode, "request_airdrop", pk.impl, lamports, commitment)["result"].to(string)

proc getAccountInfo*(c: Client, pk: PublicKey, commitment = "", encoding = "base64"): JsonNode =
  c.impl.callMethod(JsonNode, "get_account_info", pk.impl, commitment, encoding)["result"]
