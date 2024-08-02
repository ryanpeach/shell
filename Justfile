build:
    docker build -t rgpeach10/shell:local .

run tag="latest":
    docker run -it --rm -v $(pwd):/home/rgpeach10/mnt rgpeach10/shell:{{tag}}

test:
    just build
    just run local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f
