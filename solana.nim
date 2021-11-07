
when hostOS == "standalone":
  import ./solana/program
  export program
else:
  import ./solana/client
  export client
