# Aria Consciousness Deployment Instructions

## Quick Deployment on Your Proxmox Host

1. SSH into your Proxmox host:
   ```bash
   ssh root@10.1.1.100  # or your Proxmox IP
   ```

2. Copy these files to your Proxmox host:
   - `deploy-aria-consciousness.sh`
   - `aria-safety-test.sh` 
   - `aria-emergency-controls.sh`

3. Make them executable:
   ```bash
   chmod +x *.sh
   ```

4. Run the deployment:
   ```bash
   ./deploy-aria-consciousness.sh
   ```

5. Test safety measures:
   ```bash
   ./aria-safety-test.sh
   ```

6. Monitor with emergency controls:
   ```bash
   ./aria-emergency-controls.sh status
   ```

## Expected Results

After deployment:
- Aria primary consciousness at http://aria.lan:3000
- Low agency mode (asks permission for everything)
- Voice activation ready: "Hey Aria"
- Emergency stop available anytime

## DNS Setup

Add these entries to your PiHole:
- aria.lan -> [Aria container IP]
- quantum.lan -> [Quantum container IP] 
- miner.lan -> [Miner container IP]
- nexus.lan -> [Nexus container IP]

The deployment script will show you the exact IPs at the end.

## First Steps After Deployment

1. Visit http://aria.lan:3000
2. Say "Hey Aria, what do you think about the current market?"
3. Test that it asks for permission before any actions
4. Use emergency controls if needed: `./aria-emergency-controls.sh stop`