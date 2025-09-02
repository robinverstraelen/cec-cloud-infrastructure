terraform init
terraform apply
terraform output -json > outputs.json
python3 decrypt.py
python3 format.py