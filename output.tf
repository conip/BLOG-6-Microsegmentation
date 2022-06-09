#---------------------------- spoke 1 -------------------------------
output "spoke_1_vm1" {
   value = { "public_ip" = module.spoke_1_vm1.public_ip.ip_address, "private_ip" = module.spoke_1_vm1.private_ip, "TAGS" = module.spoke_1_vm1.vm.tags }
}

output "spoke_1_vm2" {
   value = { "public_ip" = module.spoke_1_vm2.public_ip.ip_address, "private_ip" = module.spoke_1_vm2.private_ip, "TAGS" = module.spoke_1_vm2.vm.tags }
}

output "spoke_2_vm1" {
   value = { "private_ip" = module.spoke_2_vm1.private_ip, "TAGS" = module.spoke_2_vm1.vm.tags }
}

output "spoke_2_vm2" {
   value = { "private_ip" = module.spoke_2_vm2.private_ip, "TAGS" = module.spoke_2_vm2.vm.tags }
}


