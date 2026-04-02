build:
    docker buildx build \
        --progress=plain \
        --build-arg UID=$(id -u) \
        --build-arg GID=$(id -g) \
        --build-arg USERNAME=$(whoami) \
        -t rgpeach10/shell:local \
        . \
        --load

run-local:
    docker run -it --rm \
        --user $(id -u) \
        -v $HOME:/home/$(whoami)/mnt \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e GITHUB_TOKEN=$(gh auth token) \
        --pull=always \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        --user $(id -u) \
        -v $HOME:/home/$(whoami)/mnt \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e GITHUB_TOKEN=$(gh auth token) \
        --pull=always \
        rgpeach10/shell:{{tag}}

build-all tag="local":
    docker buildx build \
        --progress=plain \
        --build-arg UID=$(id -u) \
        --build-arg GID=$(id -g) \
        --build-arg USERNAME=$(whoami) \
        -t rgpeach10/shell:{{tag}} \
        --platform linux/amd64,linux/arm64 \
        . \
        --push

test:
    just build
    just run-local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f

push-local: build
    echo $(git symbolic-ref --short HEAD | sed 's/\//__/g')
    docker tag rgpeach10/shell:local rgpeach10/shell:$(git symbolic-ref --short HEAD | sed 's/\//__/g')
    docker push rgpeach10/shell:$(git symbolic-ref --short HEAD | sed 's/\//__/g')

stow:
    stow -t $HOME home

stow-hard:
    stow -t $HOME --adopt home
    git reset --hard
