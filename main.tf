resource "null_resource" "test"{
	provisioner "local-exec"{
		command="Hello world - env - ${var.env}"
	}
}