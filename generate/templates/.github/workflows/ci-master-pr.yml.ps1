@'
name: ci-master-pr

on:
  push:
    branches:
    - master
  pull_request:
    branches:
    - master

jobs:
'@

$( $VARIANTS | % {
@"

  build-$( $_['tag'].Replace('.', '-') ):
    runs-on: ubuntu-18.04
    env:
      VARIANT_TAG: $( $_['tag'] )
      # VARIANT_TAG_WITH_REF: $( $_['tag'] )-`${GITHUB_REF}
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
        REF=$( echo "${GITHUB_REF}" | rev | cut -d '/' -f 1 | rev )
        SHA_SHORT=$( echo "${GITHUB_SHA}" | cut -c1-7 )

        # Generate the final tags. E.g. 'master-v1.0.0-alpine' and 'master-b29758a-v1.0.0-alpine'
        VARIANT_TAG_WITH_REF="${REF}-${VARIANT_TAG}"
        VARIANT_TAG_WITH_REF_AND_SHA_SHORT="${REF}-${SHA_SHORT}-${VARIANT_TAG}"

        docker build \
          -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_REF}" \
          -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_REF_AND_SHA_SHORT}" \
          "${VARIANT_BUILD_DIR}"
        docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_REF}"
        docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_REF_AND_SHA_SHORT}"
    - name: Clean-up
      run: docker logout
      if: always()
'@
})
