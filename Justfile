build-brew:
    docker build -t rgpeach10/brew-arm:local -f docker/brew-arm.docker .

build:
    docker build -t rgpeach10/shell:local .

run-local:
    docker run -it --rm \
        -v $HOME/.ssh:/home/user/.ssh \
        -v $HOME:/home/user/mnt \
        -w /home/user/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e DEBUG=1 \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/user/.ssh \
        -v $HOME:/home/user/mnt \
        -w /home/user/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        --pull=always \
        rgpeach10/shell:{{tag}}

test:
    just build
    just run-local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f
