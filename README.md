# Space Capybara

## Project Overview
Space Capybara is a cloud-native web application that displays images from a database and tracks visitor counts using Prometheus metrics. The project follows a modern DevOps approach, integrating Docker, Kubernetes (GKE), Helm, Terraform, GitHub Actions, and monitoring tools such as Prometheus and Grafana.

## Architecture and Workflow

<p align="center">
  <img src="https://github.com/user-attachments/assets/9bb724b1-8d61-4475-bbf0-71d86c73458e" alt="Image">
</p>

### Key Features:
- **Containerized Deployment:** Application runs in Docker containers managed via Kubernetes.
- **Automated CI/CD:** GitHub Actions pipeline builds, tests, and deploys the app.
- **Infrastructure as Code (IaC):** Terraform provisions GKE clusters.
- **Helm Package Management:** Helm handles Kubernetes deployments.
- **Monitoring & Metrics:** Prometheus collects and Grafana visualizes app metrics.
- **Automated Cleanup:** Workflow removes old Docker images and Helm charts to optimize storage.

---

## Setup Instructions
### Prerequisites
Ensure you have the following installed:
- **Docker**
- **Kubectl** (CLI tool for Kubernetes)
- **Helm** (Package manager for Kubernetes)
- **Terraform** (For provisioning GKE clusters)
- **Google Cloud SDK** (For managing GKE)
- **GitHub CLI** (For repository management)

### Steps
1. **Clone the Repository**
   ```sh
   git clone https://github.com/AlexandraFefler/devops1114_spacecapybara.git
   cd devops1114_spacecapybara
   ```
2. **Setup Environment Variables**
   Store database credentials, API keys, and other sensitive configurations as GitHub secrets.

3. **Provision GKE Cluster (Terraform)**
   ```sh
   cd tf-to-gke
   terraform init
   terraform apply --auto-approve
   ```

4. **Deploy the Application with Helm**
   ```sh
   helm repo add spacecapy https://AlexandraFefler.github.io/spacecapy-helm-chart
   helm repo update
   helm upgrade --install spacecapybara-rel spacecapy/spacecapybara-chart --namespace default
   ```

---

## CI/CD Workflow
### GitHub Actions Workflow:
1. **Build and Push Docker Image**
   - Builds a new image
   - Pushes it to Docker Hub
   - Cleans up old versions
2. **Test Application Container**
   - Runs `docker-compose` to validate the container
   - Ensures the app responds with HTTP 200
3. **Publish Helm Chart**
   - Updates `Chart.yaml` version
   - Pushes Helm chart to GitHub Pages repository
   - Cleans up older chart versions
4. **Provision and Deploy to GKE**
   - Terraform provisions cluster if necessary
   - Deploys with Helm
   - Applies Prometheus monitoring configuration

---

## Deployment Steps
1. **Trigger Workflow:** Push changes to `main` branch or create a PR.
2. **Pipeline Execution:** GitHub Actions runs the CI/CD workflow.
3. **Docker Image Build & Push:** Image is built and stored in Docker Hub.
4. **Helm Chart Packaging:** Helm updates and pushes new chart.
5. **GKE Deployment:** Helm deploys the latest application version to the GKE cluster.
6. **Verification:** Prometheus & Grafana validate app health and metrics.

---

## Security Considerations
- **Use Kubernetes Secrets:** Store database credentials securely.
- **Limit Privileges:** Avoid running containers as root.
- **Regularly Rotate Secrets:** Use GitHub Secrets to manage API keys.
- **Image Scanning:** Ensure images are vulnerability-free before deployment.
- **Enforce Role-Based Access Control (RBAC):** Restrict access to Kubernetes resources.

---

## Monitoring Setup
- **Prometheus** scrapes application metrics from `/metrics` endpoint.
- **Grafana** visualizes Prometheus data.
- **Metrics Captured:**
  - `space_capybara_visitors_total`: Tracks unique visitors.
  - Application health metrics.
- **Accessing Grafana:**
  ```sh
  kubectl port-forward svc/grafana 3000:80 -n monitoring
  ```
  Navigate to `http://localhost:3000` and log in with `admin` (default password is set in Helm values).

---

## Cleanup Automation
### Docker Image Cleanup:
- **Only latest 5 versions are kept** in Docker Hub.
- **Older versions are deleted** via a GitHub Actions job.

### Helm Chart Cleanup:
- **Only latest 5 versions are retained** in the Helm repository.
- **Older versions are deleted** via a GitHub Actions job.

---

## Contributing
1. **Fork the repository**
2. **Create a new branch** (`feature-xyz`)
3. **Commit changes** (`git commit -m 'Add new feature'`)
4. **Push to GitHub** (`git push origin feature-xyz`)
5. **Open a Pull Request**

---

## License
This project is licensed under the MIT License. See `LICENSE` for details.

