## Mongo Replica Set

resource "aws_instance" "ccie_mongodb" {
    instance_type = "${var.mongo_instance_type}"
    ami           = "${lookup(var.base_services_image, var.aws_region)}" # Probably need to change this
    count         = 3
    key_name      = "${var.aws_ssh_key_name}"
    subnet_id     = "${element(list(var.aws_subnet_id, var.aws_subnet_id_2), count.index)}"
    vpc_security_group_ids = ["${aws_security_group.circle_mongo_sg.id}"]
    #iam_instance_profile = "${module.vpc.circleci_instance_profile_name}"

    user_data = <<EOF
!/bin/bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org=3.2.3 mongodb-org-server=3.2.3 mongodb-org-shell=3.2.3 mongodb-org-mongos=3.2.3 mongodb-org-tools=3.2.3
# mongo-specific configuration / optimization
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
EOF
    disable_api_termination = false
    lifecycle {
        prevent_destroy = false
    }
    tags {
        Name      = "${var.prefix}_mongodb_${count.index + 1}"
    }
}

resource "aws_security_group" "circle_mongo_sg" {  
  name        = "${var.prefix}_mongo_sg"
  description = "MongoDB servers (terraform-managed)"
  vpc_id      = "${var.aws_vpc_id}"

  # Only postgres in
  ingress {
    security_groups = ["${aws_security_group.circleci_builders_sg.id}","${aws_security_group.circleci_services_sg.id}"]
    from_port   = "27017"
    to_port     = "27019"
    protocol    = "tcp"
    #cidr_blocks = ["${var.cidr}"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}