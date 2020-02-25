#!/usr/bin/env sh

# Check if the necessary dependencies are available
if ! command -v gsutil >/dev/null 2>&1; then
    echo "gsutil command is not available, but it's needed. Terminating..."
    exit 1
fi

if [ -z "${ORGANIZATION_ID}" ]; then
    echo 'The ORGANIZATION_ID environment variable that points to your Google Cloud organization is not defined. Terminating...'
    exit 1
fi

if [ -z "${TF_SERVICE_ACCOUNT_NAME}" ]; then
    echo 'The TF_SERVICE_ACCOUNT_NAME environment variable that points to the Google Cloud service account that Terraform will use is not defined. Terminating...'
    exit 1
fi

if [ -z "${TF_STATE_PROJECT}" ]; then
    echo 'The TF_STATE_PROJECT environment variable that points to the Google Cloud project to store the Terraform state is not defined. Terminating...'
    exit 1
fi

if [ -z "${TF_STATE_BUCKET}" ]; then
    echo 'The TF_STATE_BUCKET environment variable that points to the Google Cloud Storage bucket to store the Terraform state is not defined. Terminating...'
    exit 1
fi

if [ -z "${GOOGLE_CLOUD_PROJECT}" ]; then
    echo 'The GOOGLE_CLOUD_PROJECT environment variable that points to the default Google Cloud project that Terraform will provision the resources in is not defined. Terminating...'
    exit 1
fi

if [ -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]; then
    echo 'The GOOGLE_APPLICATION_CREDENTIALS environment variable that points to the default Google Cloud application credentials that Terraform will use is not defined. Terminating...'
    exit 1
fi

if [ -z "${GOOGLE_CLOUD_BILLING_ACCOUNT_ID}" ]; then
    echo 'The GOOGLE_CLOUD_BILLING_ACCOUNT_ID environment variable that points to the default Google Cloud billing account is not defined. Terminating...'
    exit 1
fi

if gcloud projects describe "${TF_STATE_PROJECT}" >/dev/null 2>&1; then
    echo "The ${TF_STATE_PROJECT} project already exists."
else
    echo "Creating Google Cloud project: ${ORGANIZATION_ID}/${TF_STATE_PROJECT}."
    gcloud projects create "${TF_STATE_PROJECT}" --organization="${ORGANIZATION_ID}"
fi

echo "Setting the default Google Cloud project to ${TF_STATE_PROJECT}"
gcloud config set project "${TF_STATE_PROJECT}"

if gcloud iam service-accounts describe "${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com >/dev/null 2>&1; then
    echo "The ${TF_SERVICE_ACCOUNT_NAME} service account already exists."
else
    echo "Creating the service account for Terraform"
    gcloud iam service-accounts create "${TF_SERVICE_ACCOUNT_NAME}" \
        --display-name "Terraform admin account"
fi

echo "Granting the service account permission to view the Admin Project"
gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
    --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
    --role roles/viewer

echo "Granting the service account permission to manage Cloud Storage"
gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
    --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
    --role roles/storage.admin

echo "Linking ${TF_STATE_PROJECT} to the ${GOOGLE_CLOUD_BILLING_ACCOUNT_ID} billing ID"
gcloud beta billing projects link "${TF_STATE_PROJECT}" --billing-account="${GOOGLE_CLOUD_BILLING_ACCOUNT_ID}"

echo "Creating a new Google Cloud Storage bucket to store the Terraform state in ${TF_STATE_PROJECT} project, bucket: ${TF_STATE_BUCKET}"
if gsutil ls -b -p "${TF_STATE_PROJECT}" gs://"${TF_STATE_BUCKET}" >/dev/null 2>&1; then
    echo "The ${TF_STATE_BUCKET} Google Cloud Storage bucket already exists."
else
    gsutil mb -p "${TF_STATE_PROJECT}" gs://"${TF_STATE_BUCKET}"
    gsutil versioning set on gs://"${TF_STATE_BUCKET}"
fi

TERRAFORM_BACKEND_DESCRIPTOR_PATH=../../provisioning/terraform/backend.tf
mkdir -p "${TERRAFORM_BACKEND_DESCRIPTOR_PATH}"
echo "Generating the descriptor to hold backend data in ${TERRAFORM_BACKEND_DESCRIPTOR_PATH}"
if [ -f "${TERRAFORM_BACKEND_DESCRIPTOR_PATH}" ]; then
    echo "The ${TERRAFORM_BACKEND_DESCRIPTOR_PATH} file already exists."
else
    tee "${TERRAFORM_BACKEND_DESCRIPTOR_PATH}" <<EOF
terraform {
    backend "gcs" {
        bucket  = "${TF_STATE_BUCKET}"
        prefix  = "terraform/state"
    }
}
EOF
fi
