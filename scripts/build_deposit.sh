cd "$(dirname "$0")"
mkdir -p ../build
cd ../build

cd "$(dirname "$0")"
mkdir -p ../zkeyFiles
mkdir -p ../zkeyFiles/deposit

npx circom ../circuits/deposit/deposit.circom --r1cs --wasm --sym


if [ -f ./powersOfTau28_hez_final_16.ptau ]; then
    echo "powersOfTau28_hez_final_16.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_16.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau
fi

npx snarkjs zkey new deposit.r1cs powersOfTau28_hez_final_16.ptau deposit_0000.zkey

npx snarkjs zkey contribute deposit_0000.zkey deposit_final.zkey

npx snarkjs zkey export verificationkey deposit_final.zkey verification_key.json

# snarkjs zkey export solidityverifier deposit_final.zkey verifier.sol

# mv verifier.sol ../../contracts/contracts/Verifier.sol

cp verification_key.json ../zkeyFiles/deposit/verification_key.json
cp deposit.wasm ../zkeyFiles/deposit/deposit.wasm
cp deposit_final.zkey ../zkeyFiles/deposit/deposit_final.zkey