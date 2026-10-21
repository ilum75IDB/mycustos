# Appunti sul licensing — mycustos

> Documento di lavoro interno, redatto il 2026-10-21 durante la sessione di bootstrap.
> Va rivisto in vista dell'avvio reale del progetto su GitHub (repo **pubblico**).

---

## 1. Il nome: `mycustos`

- **Etimologia**: *my* (MySQL) + *custos*, in latino "guardiano, custode".
- **Perché**: breve, comodo da digitare in un terminale, richiama MySQL e trasmette l'idea di affidabilità. Funziona bene come comando CLI (`mycustos run`, `mycustos verify`, `mycustos --version`).
- **Verifica di unicità** (ricerca web del 2026-10-21): non risulta nessuno strumento di backup MySQL o progetto GitHub con questo nome.
- **Alternative scartate**:
  - `dumpwarden`: in inglese, ma più lungo
  - `myarca`: il significato si capisce meno
- **Nomi da evitare** perché esistono già o si confondono facilmente: `mybackup`, `myback`, `automysqlbackup`, `mydumper`, `mysqlbackup` (il client di Oracle MySQL Enterprise Backup), `tabularium` (troppo simile a *Tabularis*, un client DB).

### Prima di creare il repo GitHub, ricontrollare

- [ ] `github.com/search?q=mycustos`
- [ ] pacchetti Debian / RHEL / Homebrew
- [ ] (opzionale) registro marchi EUIPO, se in futuro si vorrà proteggere il nome

> La ricerca fatta serve solo a scartare i nomi già occupati: **non ha valore legale**.

---

## 2. Licenza scelta: Apache-2.0 con file `NOTICE`

### Perché Apache-2.0

| Requisito di Ivan | Come lo soddisfa Apache-2.0 |
|---|---|
| Garantire nel tempo la paternità del progetto | §4(c): chi ridistribuisce, anche con modifiche, deve **mantenere tutte le note di copyright e attribuzione** presenti nel sorgente |
| Impedire di togliere o cambiare il nome dell'autore | §4(d): il file `NOTICE` va **incluso in ogni opera derivata ridistribuita**. Lì si mettono nome dell'autore, anno e URL del progetto originale |
| Proteggere il nome "mycustos" | §6: la licenza **non concede l'uso dei marchi**. Un fork può esistere, ma non può presentarsi come il progetto ufficiale |
| Favorire l'adozione da parte dei clienti target (banche, PA, utility) | È permissiva e il mondo enterprise la conosce bene. Di solito passa la revisione legale senza attriti, mentre la GPL spesso spaventa |
| Tutela legale sui brevetti | §3: concessione esplicita della licenza sui brevetti + clausola di ritorsione in caso di contenzioso |

### Alternativa valutata: GPL-3.0 con clausola 7(b)

- La §7(b) della GPL-3.0 permette di aggiungere un termine che **impone di conservare le attribuzioni d'autore**.
- **Pro**: copyleft. Chi modifica e ridistribuisce deve rilasciare anche il proprio codice, quindi la protezione dell'opera è più forte.
- **Contro**: frena l'adozione in ambito enterprise, che è proprio il mercato di riferimento di IDEA DB CONSULTING.
- **Verdetto**: scartata per ora. Da riconsiderare solo se si vuole impedire che il codice finisca in prodotti chiusi.

### Limiti da conoscere (valgono per qualsiasi licenza open source)

1. **Nessuna licenza open source può vietare di rinominare un fork.** Può però impedire di **togliere il nome dell'autore originale**, ed è questo l'obiettivo reale. Per blindare il nome "mycustos" l'unica strada è la **registrazione del marchio**.
2. **In Italia la paternità è tutelata per legge**, con o senza licenza: il diritto morale d'autore (art. 20, L. 633/1941) non si può cedere né si estingue. La licenza serve a renderlo **visibile e opponibile anche all'estero**.

---

## 3. Come proporre la licenza nel repo

### 3.1 `LICENSE`

Testo integrale di Apache License 2.0, **senza modifiche**. Il modo più semplice è selezionare "Apache License 2.0" al momento della creazione del repo su GitHub, che lo genera automaticamente.

### 3.2 `NOTICE` (root del repo)

```
mycustos — Standardized MySQL backup runner
Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
https://github.com/ilum75IDB/mycustos

This product includes software developed by Ivan Luminaria.
Redistributions must retain this NOTICE file and the attribution above.
```

### 3.3 Header SPDX in ogni script

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
```

### 3.4 Sezione "Licenza e attribuzione" nel README

Testo di partenza (in inglese, per un repo pubblico internazionale):

```markdown
## License & attribution

mycustos is released under the [Apache License 2.0](LICENSE).
You are free to use, modify and redistribute it, provided that you keep the
`LICENSE` and `NOTICE` files and the copyright headers in the source files.

"mycustos" identifies the original project by Ivan Luminaria.
Forks and derivative works must not present themselves as the official project.
```

### 3.5 Firma nello script (opzionale ma consigliata)

Fai stampare a `mycustos --version` una riga del tipo:

```
mycustos vX.Y.Z — © Ivan Luminaria — Apache-2.0 — https://github.com/ilum75IDB/mycustos
```

Così il nome dell'autore resta visibile su ogni server dove lo script gira.

### 3.6 Contributi esterni (quando arriveranno)

- Valutare un **DCO** (Developer Certificate of Origin, `Signed-off-by:` nei commit) oppure un `CONTRIBUTING.md` che dichiari che i contributi sono accettati sotto Apache-2.0.
- Così la titolarità del progetto resta chiara anche con più contributori.

---

## 4. ⚠️ Attenzione: separazione da mysql-controlli

Se questo progetto riprende logica o codice da **mysql-controlli** (il sostituto del sistema di controlli MySQL di un cliente), nel repo **pubblico** non deve finire nulla di riconducibile al cliente:

- hostname, IP, path specifici del cliente
- convenzioni di naming o file nati per il cliente
- codice scritto su commessa, il cui diritto di riuso va verificato contrattualmente

**Regola**: la base di mycustos deve essere **generica**. Prima del primo push pubblico va fatta una revisione mirata (grep di hostname, IP, nomi cliente, credenziali).

---

## 5. Checklist per l'avvio GitHub

- [ ] Ricontrollare l'unicità del nome (§1)
- [ ] Creare il repo `ilum75IDB/mycustos` **pubblico** con licenza Apache-2.0
- [ ] Aggiungere `NOTICE` (§3.2)
- [ ] Header SPDX su ogni script (§3.3)
- [ ] Sezione "License & attribution" nel README (§3.4)
- [ ] `--version` con attribuzione (§3.5)
- [ ] Revisione anti-dati-cliente prima del primo push (§4)
- [ ] Decidere la politica sui contributi esterni (§3.6)
