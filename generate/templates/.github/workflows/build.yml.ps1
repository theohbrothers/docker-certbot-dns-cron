@'
name: build

on:
  push:
    branches:
    - '**'
    tags:
    - '**'
  pull_request:
    branches:
    - '**'

jobs:
'@

$( $VARIANTS | % {
@"

  build-$( $_['tag'].Replace('.', '-') ):
    runs-on: ubuntu-18.04
    env:
      VARIANT_TAG: $( $_['tag'] )
      # VARIANT_TAG_WITH_VERSION: $( $_['tag'] )-`${GITHUB_REF}
      VARIANT_BUILD_DIR: $( $_['build_dir_rel'] )
"@
@'

    steps:
    - uses: actions/checkout@v1
    - name: Display system info (linux)
      run: |
        set -e
        hostname
        whoami
        cat /etc/*release
        lscpu
        free
        df -h
        pwd
        docker info
        docker version
    - name: Login to docker registry
      run: echo "${DOCKERHUB_REGISTRY_PASSWORD}" | docker login -u "${DOCKERHUB_REGISTRY_USER}" --password-stdin
      env:
        DOCKERHUB_REGISTRY_USER: ${{ secrets.DOCKERHUB_REGISTRY_USER }}
        DOCKERHUB_REGISTRY_PASSWORD: ${{ secrets.DOCKERHUB_REGISTRY_PASSWORD }}
    - name: Build and push image
      env:
        DOCKERHUB_REGISTRY_USER: ${{ secrets.DOCKERHUB_REGISTRY_USER }}
      run: |
        set -e

        # Get 'project-name' from 'namespace/project-name'
        CI_PROJECT_NAME=$( echo "${GITHUB_REPOSITORY}" | rev | cut -d '/' -f 1 | rev )

        # Get 'ref-name' from 'refs/heads/ref-name'
        VARIANT_TAG_WITH_VERSION=$( echo "${GITHUB_REF}" | rev | cut -d '/' -f 1 | rev )

        docker build \
          -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG}" \
          -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_VERSION}" \
          -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:latest" \
          "${VARIANT_BUILD_DIR}"
        docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG}"
        docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_VERSION}"
        docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:latest"
    - name: Clean-up
      run: docker logout
      if: always()
'@
})
