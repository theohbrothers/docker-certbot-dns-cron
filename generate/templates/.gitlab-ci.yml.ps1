@"
image: docker:latest
services:
  - docker:dind
variables:
  DOCKER_DRIVER: overlay2

stages:
  - build

$( $VARIANTS | % {
@"

build-$( $_['name'] ):
  stage: build
  only:
    - master
    - api
  variables:
    VARIANT_NAME: "$( $_['name'] )"
    VARIANT_TAG: "$( $_['name'] )"
    VARIANT_TAG_WITH_VERSION: "$( $_['name'] )-v$( $_['version'] )"
"@ + @'

  before_script:
    - date '+%Y-%m-%d %H:%M:%S %z'

    # Login to Docker Hub registry
    - echo "${DOCKERHUB_REGISTRY_PASSWORD}" | docker login -u "${DOCKERHUB_REGISTRY_USER}" --password-stdin

    # Login to GitLab registry
    - echo "${CI_REGISTRY_PASSWORD}" | docker login -u "${CI_REGISTRY_USER}" --password-stdin "${CI_REGISTRY}"

  script:
    - date '+%Y-%m-%d %H:%M:%S %z'
    - docker build
      -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG}"
      -t "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_VERSION}"
      -t "${CI_REGISTRY_IMAGE}:${VARIANT_TAG}"
      -t "${CI_REGISTRY_IMAGE}:${VARIANT_TAG_WITH_VERSION}"
      "./variants/${VARIANT_NAME}"

    - date '+%Y-%m-%d %H:%M:%S %z'

    # Push to Docker Hub registry. E.g. 'namespace/my-project:tag'
    - docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG}"
    - docker push "${DOCKERHUB_REGISTRY_USER}/${CI_PROJECT_NAME}:${VARIANT_TAG_WITH_VERSION}"

    # Push to GitLab registry. E.g. 'registry.gitlab.com/namespace/my-project:tag
    - docker push "${CI_REGISTRY_IMAGE}:${VARIANT_TAG}"
    - docker push "${CI_REGISTRY_IMAGE}:${VARIANT_TAG_WITH_VERSION}"

  after_script:
    - date '+%Y-%m-%d %H:%M:%S %z'

    # Log out of Docker Hub registry
    - docker logout

    # Log out of GitLab registry
    - docker logout "${CI_REGISTRY}"

'@
})

"@