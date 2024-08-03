build:
    docker build -t rgpeach10/shell:local .

run-local:
    docker run -it --rm \
        -v $HOME/.ssh:/home/rgpeach10/.ssh \
        -v $HOME:/home/rgpeach10/mnt \
        -w /home/rgpeach10/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e DEBUG=1 \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/rgpeach10/.ssh \
        -v $HOME:/home/rgpeach10/mnt \
        -w /home/rgpeach10/mnt \
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
