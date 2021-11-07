import solana

type
  Pubkey* = object
    x: array[32, byte]

  AccountInfo* = object
    key*: ptr Pubkey
    lamports*: ptr uint64
    data_len*: uint64
    data*: pointer
    owner*: ptr Pubkey
    rentEpoch*: uint64
    isSigner*: bool
    isWritable*: bool
    executable*: bool

  Parameters* = object
    ka*: ptr UncheckedArray[AccountInfo]
    kaNum*: uint64
    data*: pointer
    dataLen*: uint64
    programId*: ptr PubKey

template toBuiltin(error: uint64): uint64 =
  error shl 32

const
  SUCCESS = 0
#/** Note: Not applicable to program written in C */
  ERROR_CUSTOM_ZERO = toBuiltin(1)
#/** The arguments provided to a program instruction where invalid */
  ERROR_INVALID_ARGUMENT = toBuiltin(2)
#/** An instruction's data contents was invalid */
  ERROR_INVALID_INSTRUCTION_DATA = toBuiltin(3)
#/** An account's data contents was invalid */
  ERROR_INVALID_ACCOUNT_DATA = toBuiltin(4)
#/** An account's data was too small */
  ERROR_ACCOUNT_DATA_TOO_SMALL = toBuiltin(5)
#/** An account's balance was too small to complete the instruction */
  ERROR_INSUFFICIENT_FUNDS = toBuiltin(6)
#/** The account did not have the expected program id */
  ERROR_INCORRECT_PROGRAM_ID = toBuiltin(7)
#/** A signature was required but not found */
  ERROR_MISSING_REQUIRED_SIGNATURES = toBuiltin(8)
#/** An initialize instruction was sent to an account that has already been initialized */
  ERROR_ACCOUNT_ALREADY_INITIALIZED = toBuiltin(9)
#/** An attempt to operate on an account that hasn't been initialized */
  ERROR_UNINITIALIZED_ACCOUNT = toBuiltin(10)
#/** The instruction expected additional account keys */
  ERROR_NOT_ENOUGH_ACCOUNT_KEYS = toBuiltin(11)
#/** Note: Not applicable to program written in C */
  ERROR_ACCOUNT_BORROW_FAILED = toBuiltin(12)
#/** The length of the seed is too long for address generation */
  MAX_SEED_LENGTH_EXCEEDED = toBuiltin(13)
#/** Provided seeds do not result in a valid address */
  INVALID_SEEDS = toBuiltin(14)


const MAX_PERMITTED_DATA_INCREASE = 1024 * 10

proc sol_log(data: cstring, len: uint64) {.importc: "sol_log_".}
proc sol_log_pubkey(pk: ptr Pubkey) {.importc: "sol_log_pubkey".}
proc sol_log_64(a, b, c, d, e: uint64) {.importc: "sol_log_64_".}
proc log(data: string) {.inline.} = sol_log(data, uint64(data.len))
proc log(pk: Pubkey) {.inline.} = sol_log_pubkey(unsafeAddr pk)
proc log(a: uint64) {.inline.} = sol_log_64(0, 0, 0, 0, a)
proc log(a, b: uint64) {.inline.} = sol_log_64(0, 0, 0, a, b)
proc log(a, b, c: uint64) {.inline.} = sol_log_64(0, 0, a, b, c)
proc log(a, b, c, d: uint64) {.inline.} = sol_log_64(0, a, b, c, d)
proc log(a, b, c, d, e: uint64) {.inline.} = sol_log_64(a, b, c, d, e)

proc logComputeUnits() {.importc: "sol_log_compute_units_".}


proc sol_deserialize(input: pointer, params: var Parameters, kaNum: int): bool =
  if input.isNil:
    return false

  var input = cast[ptr UncheckedArray[uint8]](input)

  template `+=`(i: var ptr UncheckedArray[uint8], by: int) =
    i = cast[ptr UncheckedArray[uint8]](cast[int64](i) + int64(by))

  template `+=`(i: var ptr UncheckedArray[uint8], by: uint64) =
    i += int(by)

  params.ka_num = cast[ptr uint64](input)[]
  input += sizeof(uint64)

  for i in 0 ..< int(params.kaNum):
    let dup_info = input[0]
    input += sizeof(uint8);

    if i >= kaNum:
      if dup_info == uint8.high:
        input += sizeof(uint8);
        input += sizeof(uint8);
        input += sizeof(uint8);
        input += 4; # padding
        input += sizeof(Pubkey);
        input += sizeof(Pubkey);
        input += sizeof(uint64);
        let data_len = cast[ptr uint64](input)[]
        input += sizeof(uint64);
        input += data_len;
        input += MAX_PERMITTED_DATA_INCREASE;
        input = cast[ptr UncheckedArray[uint8]]((cast[uint64](input) + 8 - 1) and cast[uint64](not(8 - 1))); # padding
        input += sizeof(uint64);
      else:
        input += 7; # padding
      continue

    if dup_info == uint8.high:
      # is signer?
      params.ka[i].is_signer = input[0] != 0
      input += sizeof(uint8);

      # is writable?
      params.ka[i].is_writable = input[0] != 0;
      input += sizeof(uint8);

      # executable?
      params.ka[i].executable = input[0] != 0;
      input += sizeof(uint8);

      input += 4; # padding

      # key
      params.ka[i].key = cast[ptr Pubkey](input)
      input += sizeof(Pubkey);

      # owner
      params.ka[i].owner = cast[ptr Pubkey](input)
      input += sizeof(Pubkey);

      # lamports
      params.ka[i].lamports = cast[ptr uint64](input)
      input += sizeof(uint64);

      # account data
      params.ka[i].data_len = cast[ptr uint64](input)[]
      input += sizeof(uint64);
      params.ka[i].data = input;
      input += params.ka[i].data_len;
      input += MAX_PERMITTED_DATA_INCREASE;
      input = cast[ptr UncheckedArray[uint8]]((cast[uint64](input) + 8 - 1) and cast[uint64](not(8 - 1))); # padding

      # rent epoch
      params.ka[i].rent_epoch = cast[ptr uint64](input)[]
      input += sizeof(uint64);
    else:
      params.ka[i].is_signer = params.ka[dup_info].is_signer;
      params.ka[i].is_writable = params.ka[dup_info].is_writable;
      params.ka[i].executable = params.ka[dup_info].executable;
      params.ka[i].key = params.ka[dup_info].key;
      params.ka[i].owner = params.ka[dup_info].owner;
      params.ka[i].lamports = params.ka[dup_info].lamports;
      params.ka[i].data_len = params.ka[dup_info].data_len;
      params.ka[i].data = params.ka[dup_info].data;
      params.ka[i].rent_epoch = params.ka[dup_info].rent_epoch;
      input += 7; # padding

  params.data_len = cast[ptr uint64](input)[]
  input += sizeof(uint64);
  params.data = input;
  input += params.data_len;

  params.program_id = cast[ptr Pubkey](input)
  input += sizeof(Pubkey);

  return true

# proc helloworld(params: Parameters): uint64 =
#   if params.kaNum < 1:
#     log("Greeted account not included in the instruction")
#     return ERROR_NOT_ENOUGH_ACCOUNT_KEYS

#   # Get the account to say hello to
#   let greeted_account = addr params.ka[0]

#   # The account must be owned by the program in order to modify its data
#   if greeted_account.owner[] != params.programId[]:
#     log("Greeted account does not have the correct program id")
#     return ERROR_INCORRECT_PROGRAM_ID

#   # The data must be large enough to hold an uint32_t value
#   if greeted_account.data_len < sizeof(uint32).uint64:
#     log("Greeted account data length too small to hold uint32 value")
#     return ERROR_INVALID_ACCOUNT_DATA

#   # Increment and store the number of times the account has been greeted
#   let numGreets = cast[ptr uint32](greeted_account.data)
#   inc numGreets[]

#   log("Hello!")

#   return SUCCESS

proc mainDispatch(input: pointer, p: proc(programId: Pubkey, accounts: openarray[AccountInfo], instructionData: openarray[byte]): uint64 {.nimcall.}): uint64 =
  var accounts: array[1, AccountInfo]
  var params: Parameters
  params.ka = cast[ptr UncheckedArray[AccountInfo]](addr accounts)

  if not sol_deserialize(input, params, accounts.len):
    return ERROR_INVALID_ARGUMENT

  return p(params.programId[], toOpenArray(params.ka, 0, params.kaNum.int), toOpenArray(cast[ptr UncheckedArray[byte]](params.data), 0, params.dataLen.int))


template entrypoint(p: proc(programId: Pubkey, accounts: openarray[AccountInfo], instructionData: openarray[byte]): uint64 {.nimcall.}) =
  proc `$$$main`(input: pointer): uint64 {.exportc: "entrypoint".} = mainDispatch(input, p)

proc entry(programId: Pubkey, accounts: openarray[AccountInfo], instructionData: openarray[byte]): uint64 =
  if accounts.len < 1:
    log("Greeted account not included in the instruction")
    return ERROR_NOT_ENOUGH_ACCOUNT_KEYS

  # Get the account to say hello to
  let greeted_account = unsafeAddr accounts[0]

  # The account must be owned by the program in order to modify its data
  if greeted_account.owner[] != programId:
    log("Greeted account does not have the correct program id")
    return ERROR_INCORRECT_PROGRAM_ID

  # The data must be large enough to hold an uint32_t value
  if greeted_account.data_len < sizeof(uint32).uint64:
    log("Greeted account data length too small to hold uint32 value")
    return ERROR_INVALID_ACCOUNT_DATA

  # Increment and store the number of times the account has been greeted
  let numGreets = cast[ptr uint32](greeted_account.data)
  inc numGreets[]

  log("Hello!")

  return SUCCESS

entrypoint(entry)
