# ═══════════════════════════════════════════════════════════
# terraform.tfvars
#
# Steps:
# 1. Copy this file: cp terraform.tfvars.example terraform.tfvars
# 2. Fill your actual values below
# 3. NEVER commit terraform.tfvars to Git!
# ═══════════════════════════════════════════════════════════

# Your EC2 key pair name (created in AWS Console → EC2 → Key Pairs)
key_name = "padmasree"

# Your public IP - run this to get it: curl ifconfig.me
# Must include /32 at the end
my_ip = "106.222.228.194/32"
