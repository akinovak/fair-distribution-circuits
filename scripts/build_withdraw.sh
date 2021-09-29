cd "$(dirname "$0")"
mkdir -p ../build
cd ../build

cd "$(dirname "$0")"
mkdir -p ../zkeyFiles
mkdir -p ../zkeyFiles/withdraw

npx circom ../circuits/withdraw/withdraw.circom --r1cs --wasm --sym


if [ -f ./powersOfTau28_hez_final_16.ptau ]; then
    echo "powersOfTau28_hez_final_16.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_16.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau
fi

npx snarkjs zkey new withdraw.r1cs powersOfTau28_hez_final_16.ptau withdraw_0000.zkey

npx snarkjs zkey contribute withdraw_0000.zkey withdraw_final.zkey

npx snarkjs zkey export verificationkey withdraw_final.zkey verification_key.json

snarkjs zkey export solidityverifier withdraw_final.zkey verifier.sol


cp verifier.sol ../zkeyFiles/withdraw/verifier.sol
cp verification_key.json ../zkeyFiles/withdraw/verification_key.json
cp withdraw.wasm ../zkeyFiles/withdraw/withdraw.wasm
cp withdraw_final.zkey ../zkeyFiles/withdraw/withdraw_final.zkey