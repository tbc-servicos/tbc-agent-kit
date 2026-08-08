---
name: base
description: Sobe um sandbox Fluig DESCARTÁVEL em Docker na MÁQUINA DO DEV (nunca na VPS de trabalho) para o inner loop do agente — implementar, deployar e rodar E2E com log limpo e reset em segundos. Usa o projeto open-source fluig-docker-dev (instalador oficial baixado pelo próprio dev). Use quando o dev pedir "subir um fluig", "sandbox fluig", "ambiente fluig local" ou quando o ciclo precisar de E2E isolado.
---

Você vai subir um ambiente Fluig descartável para desenvolvimento e teste E2E isolado.

## ⚠️ ONDE RODAR — leia antes de qualquer comando

**Este sandbox sobe na MÁQUINA DO DEV, nunca no servidor de trabalho/homologação da equipe.**

O servidor Fluig de trabalho da equipe é o ambiente de **entrega** — é onde o `/fluig:deploy`
publica para homologação e onde o cliente valida. Subir instância de sandbox lá:
- rouba RAM do ambiente de entrega da equipe (o Fluig pede no mínimo 8G de máquina);
- polui o log do servidor — e "erro no log durante o teste" é risco **ALTO por
  definição** na lista fechada do `/fluig:qa`: tráfego de sandbox alheio gera falso
  ALTO para os outros devs.

Antes de subir, confirme com o dev:

> "Este sandbox vai rodar **nesta máquina** (precisa de ~8 GB de RAM livres e Docker).
> O servidor de trabalho fica intocado — ele é só o destino de homologação. Confirma?"

Se a máquina do dev não tem 8 GB livres, a alternativa é UMA instância de sandbox em
servidor próprio de infra **com autorização de quem administra** — nunca por padrão.

Cheque os recursos antes de prosseguir (comandos Linux; em Docker Desktop
Mac/Windows, confira RAM/disco nas configurações do Docker):

```bash
docker info >/dev/null 2>&1 && echo "docker ok" || echo "instale o Docker primeiro"
free -g | awk '/Mem:/ {print "RAM livre (GB): " $7}'   # precisa de ~8 (recomendado 12)
df -h . | awk 'NR==2 {print "disco livre: " $4}'        # instalação ~12 GB + volumes
```

## O que é (e o que não é)

- Baseado no projeto open-source **`fluig-docker-dev`** (MIT, comunidade): Dockerfile
  que roda o **instalador oficial do Fluig** dentro do container + MySQL 8 (a opção
  leve de banco) + MailDev para inspecionar e-mails.
- **O instalador é baixado pelo PRÓPRIO dev na Central do Cliente TOTVS** — nem o
  instalador nem a imagem buildada podem ser redistribuídos.
- **Não é ambiente suportado pela TOTVS e nunca vai para produção** — a TOTVS não
  publica imagem Docker de Fluig; isto é automação do instalador oficial, para
  desenvolvimento.
- **Licença:** sem License Server configurado o Fluig entra em **modo demonstração —
  todos os recursos, 1 usuário ativo** (TDN "Modo demonstração"), que é exatamente o
  perfil de um agente rodando E2E. O README do projeto fala em **7 dias** de modo
  demonstração (o TDN não documenta prazo) — irrelevante para sandbox descartável:
  derrube e suba outro. Para mais de um usuário simultâneo, aponte o License Server
  da empresa (porta 5555, slot 4012) — licenças Fluig contam por **identidade**, e o
  pool contratado pode ser usado em dev/homologação sem custo adicional (TDN
  "Licenciamento da plataforma").

## Passo 1 — Obter o projeto e o instalador

```bash
git clone https://github.com/brunogasparetto/fluig-docker-dev.git
cd fluig-docker-dev
# Baixe o instalador Linux 64 do Fluig na Central do Cliente TOTVS e coloque o
# CONTEÚDO em image/installer/ — a estrutura esperada (INSTALACAO.md do projeto):
#   fluig-installer-64.sh, fluig-installer.jar, wildfly-dist.zip, openoffice.zip,
#   jdk-64/, packs/
```

O projeto instala **Fluig 2.0 ou 1.8** (`.env` → `FLUIG=2.0|1.8`). Se a homologação
do cliente roda outra release, este sandbox **não** a reproduz — diga isso ao dev em
vez de fingir paridade (o E2E de comportamento dependente de versão vai para a
homologação).

## Passo 2 — Subir

```bash
docker compose up -d --build   # primeiro build roda o instalador: demora
docker compose logs -f fluig   # acompanhe até o boot completar (minutos)
```

Acesso padrão do projeto (valores do compose upstream): **Fluig em
`http://localhost:8080`** (WCMAdmin em `/wcmadmin`, login `wcmadmin` / senha `adm`),
MailDev em `http://localhost:1080`, MySQL em `localhost:3306` (root/rootpassword).
Primeiro acesso: o `wcmadmin` cria a empresa de trabalho; cada empresa usa um
subdiretório do volume (`/var/fluig-volume/empresa001`).

> Se a porta `1080` já estiver em uso na sua máquina (proxies SOCKS costumam usá-la),
> remapeie o MailDev no compose (ex.: `1081:1080`) antes do `up`.

## Passo 3 — Perfil de recursos (este JÁ é o perfil leve)

O projeto é a combinação leve viável: **MySQL** como banco (vs SQL Server), e os
componentes opcionais **desligados por padrão** (`INSTALL_NODE=false`,
`INSTALL_SOLR=false` no build). O piso real é o do TDN para homologação: **8G de
RAM de máquina** (recomendado 12G; produção oficial pede 16G por instância) — o
compose upstream **não define limite de container**, então numa máquina justa vale
acrescentar `mem_limit: 8g` ao serviço fluig para o WildFly não engolir o host.
Abaixo de 8G de máquina não insista: é fura-piso do TDN.

## Passo 4 — Usar no ciclo

- `/fluig:deploy` pode publicar **no sandbox** durante o inner loop (alvo
  `http://localhost:8080`, credenciais locais) — homologação continua sendo o servidor da equipe.
  **Os gates do `/fluig:implement` (testes, lint, reviews) valem igual** — o sandbox
  muda o ALVO do deploy do inner loop, não pula gate nenhum.
- `/fluig:test-web` e `/fluig:qa` rodam E2E contra o sandbox com **log limpo**: um
  erro no log do servidor durante o teste é do SEU código, não de tráfego alheio.
- Sandbox é **servidor Fluig real** — a regra "nunca localhost" do E2E existe para
  impedir teste contra mock/porta morta, não contra uma instância descartável
  saudável.

## Reset e descarte

```bash
docker compose down                      # para tudo
docker volume rm <projeto>_fluig-volume  # zera documentos/volumes da empresa
docker compose up -d                     # renasce zerado
```

Reset total em segundos — é a razão de este sandbox existir. Estado que precisa
sobreviver (formulário publicado, processo modelado) pertence à homologação, não
ao sandbox.

## Regras

- **Nunca no servidor de trabalho da equipe** sem autorização explícita de quem o administra.
- Nunca redistribuir instalador ou imagem buildada.
- Nunca usar o sandbox como ambiente de homologação/entrega — o resultado que o
  cliente valida sai do servidor de homologação, via `/fluig:deploy` normal.
- Sandbox velho não se conserta: derrube e suba outro.
