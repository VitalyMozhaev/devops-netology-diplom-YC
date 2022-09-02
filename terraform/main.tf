# instances

resource "yandex_compute_instance" "cp" {
  name = "cp"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83clk0nfo8p172omkn"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-a.id
    nat        = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }
}

resource "yandex_compute_instance" "node1" {
  name = "node1"
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83clk0nfo8p172omkn"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-b.id
    nat        = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }
}


resource "yandex_compute_instance" "node2" {
  name = "node2"
  zone = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83clk0nfo8p172omkn"
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-c.id
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }
}
