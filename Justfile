build:
    docker build -t user/shell:local .

run-local:
    docker run -it --rm \
        -v $HOME/.ssh:/home/user/.ssh \
        -v $HOME:/home/user/mnt \
        -w /home/user/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/rgpeach10/mnt \
        -e DEBUG=1 \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/user/.ssh \
        -v $HOME:/home/user/mnt \
        -w /home/user/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/rgpeach10/mnt \
        --pull=always \
        rgpeach10/shell:{{tag}}

test:
    just build
    just run-local

sort:
    ./sort_dockerfile.sh

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f
