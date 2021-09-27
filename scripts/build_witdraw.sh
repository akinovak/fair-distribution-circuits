cd "$(dirname "$0")"
mkdir -p ../build
cd ../build

cd "$(dirname "$0")"
mkdir -p ../zkeyFiles
mkdir -p ../zkeyFiles/witdraw

npx circom ../circuits/witdraw/witdraw.circom --r1cs --wasm --sym


if [ -f ./powersOfTau28_hez_final_16.ptau ]; then
    echo "powersOfTau28_hez_final_16.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_16.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau
fi

npx snarkjs zkey new witdraw.r1cs powersOfTau28_hez_final_16.ptau witdraw_0000.zkey

npx snarkjs zkey contribute witdraw_0000.zkey witdraw_final.zkey

npx snarkjs zkey export verificationkey witdraw_final.zkey verification_key.json

# snarkjs zkey export solidityverifier witdraw_final.zkey verifier.sol

# mv verifier.sol ../../contracts/contracts/Verifier.sol

cp verification_key.json ../zkeyFiles/witdraw/verification_key.json
cp witdraw.wasm ../zkeyFiles/witdraw/witdraw.wasm
cp witdraw_final.zkey ../zkeyFiles/witdraw/witdraw_final.zkey