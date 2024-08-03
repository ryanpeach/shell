build:
    docker buildx build -t rgpeach10/shell:local --load .

run tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/rgpeach10/.ssh \
        -v $HOME/.config/gh:/home/rgpeach10/.config/gh \
        -v $HOME:/home/rgpeach10/mnt \
        -w /home/rgpeach10/mnt \
        --pull=always \
        rgpeach10/shell:main

test:
    just build
    just run local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f
