# Mindustry Cloud Server Deployment (OCI + Docker)

This guide outlines the end-to-end process for deploying a Mindustry game server on an **Oracle Cloud Infrastructure (OCI)** Ubuntu instance using Docker.

## 1. Cloud Infrastructure Setup
### Virtual Cloud Network (VCN) & Subnet
* Ensure your instance is in a **Public Subnet**.
* Verify the **Route Table** for the subnet has a rule:
    * **Destination:** `0.0.0.0/0`
    * **Target Type:** `Internet Gateway`
    * **Target:** `Your_VCN_Internet_Gateway`

### Security Lists (The Cloud Firewall)
Create a specific Security List (e.g., `minedustry_sl_01`) or edit the **Default Security List** to include these **Ingress Rules**:

| Protocol | Source CIDR | Port Range | Description |
| :--- | :--- | :--- | :--- |
| **TCP** | `0.0.0.0/0` | `6567` | Mindustry Game Traffic |
| **UDP** | `0.0.0.0/0` | `6567` | Mindustry Game Traffic |
| **ICMP** | `0.0.0.0/0` | Type 8, Code All | Enables Ping/Echo |

> **Note:** Attach this Security List to your Subnet under the **Security Lists** tab in the OCI Console.

---

## 2. OS Level Configuration (Ubuntu)
### Provisioning Virtual RAM (Swap)
Because the OCI "Always Free" micro instance only has 1GB of RAM, you **must** create a swap file to prevent the Java process from being killed by the OOM (Out of Memory) manager.

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Opening OS Ports (iptables)
Ubuntu on Oracle Cloud blocks all ports except SSH by default. Run these to punch through the OS firewall:

```bash
sudo iptables -I INPUT 6 -p tcp --dport 6567 -j ACCEPT
sudo iptables -I INPUT 6 -p udp --dport 6567 -j ACCEPT
sudo iptables -I INPUT 6 -p icmp --icmp-type echo-request -j ACCEPT

# Make rules persistent
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

---

## 3. Docker Deployment
### Launch the Container
Run the container with interactive flags (`-it`) to allow console access later.

```bash
docker run -d \
  -it \
  --name mindustry-server \
  -p 6567:6567/tcp \
  -p 6567:6567/udp \
  --restart always \
  ghcr.io/krishjp/minedustry-docker:latest
```

### Accessing the Game Console
To start hosting or manage the server, you must attach to the running process:

1.  **Attach:** `docker attach mindustry-server`
2.  **Initialize:** Press **Enter** to see the `>` prompt.
3.  **Host Map:** Type the hosting command:
    ```text
    host survival Ancient_Caldera
    ```
4.  **Detach (Crucial):** To exit the console without stopping the server, press:
    **`Ctrl + P`** followed by **`Ctrl + Q`**.

---

## 4. Maintenance & Monitoring
* **Check Status:** `docker ps`
* **View Logs:** `docker logs -f mindustry-server`
* **Check Memory Usage:** `free -h` or `docker stats`

---

## 5. Troubleshooting
* **Ping works but Game doesn't:** Check if the Mindustry server is actually hosting. Run `docker logs` and look for `[I] Server started on port 6567`.
* **Connection Timed Out:** Re-verify the **UDP** Ingress rule in OCI and the `iptables` rules on the VM.
* **Container keeps restarting:** Usually indicates an OOM crash. Ensure the Swap file is active (`swapon --show`).
