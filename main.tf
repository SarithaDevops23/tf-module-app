resource "null_resource" "test"{
	triggers={
		xyz=timestamp()
	}
	provisioner "local-exec"{
		command = "Hello world - env - ${var.env}"
	}
}