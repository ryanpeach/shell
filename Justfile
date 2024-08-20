build:
    docker buildx build -t rgpeach10/shell:local . --load

run-local:
    docker run -it --rm \
        -v $HOME/.ssh:/home/root/.ssh \
        -v $HOME:/home/root/mnt \
        -w /home/root/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/root/mnt \
        -e DEBUG=1 \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/root/.ssh \
        -v $HOME:/home/root/mnt \
        -w /home/root/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/root/mnt \
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
