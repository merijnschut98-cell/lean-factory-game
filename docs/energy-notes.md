# Energy-sector notes for Merijn

Running notes on the Dutch energy sector, collected while researching *Spanning*. Every Friday they are turned into a short digest focused on what matters for a Lean / CI consultant who wants to work in the sector. Digested notes move into a dated section below.

Sources were read through search-engine extracts (this environment blocks direct access to most news sites); verify before quoting them in a conversation.

## This week (from 2026-10-16)

*(Notes collected while building Spanning land here; the Friday digest moves them into a dated section.)*

## Digest 2026-10-16

A quieter week. No new ACM decision, no new technician or scale-up figures, and no Lean or CI vacancies at the grid operators were found. All items below come from search snippets; verify them before quoting.

### News this week (9–16 Oct)
- **The grid operators now buy flexibility through an auction.** Liander, Enexis and Stedin launched **GOPACS Auctions**, one public place to request flexible capacity, with TenneT joining later.
  - They published **496 MW** of need at launch. *Verified 2026-10-16*: Netbeheer Nederland's news item of 13 Oct 2026 says the operators published a need of 496 MW before the release, and that TenneT joins later.
  - ~~Bidders need a metered EAN connection and usually at least 100 kW.~~ **Unverified, do not use in content.** The Netbeheer Nederland page states neither figure; it only says CSPs bid on behalf of large business customers.
  - ~~Cross-operator calls change from **1 Nov 2026**.~~ **Unverified, do not use in content.** The date is not on the Netbeheer Nederland page (read 2026-10-16); it came from a gopacs.eu search snippet, and gopacs.eu is not an approved domain. Needed to confirm: gopacs.eu (the GOPACS FAQ / release notes), pending Merijn's approval.
  - Sources: [Netbeheer Nederland](https://www.netbeheernederland.nl/artikelen/nieuws/netbeheerders-lanceren-gopacs-auctions-voor-openbare-uitvraag-naar-flexibel), [GOPACS FAQ](https://www.gopacs.eu/en/frequently-asked-questions/) (from search snippet)
- **61% of postcodes on the regional grid are full for offtake**, based on the capacity map of 12 Oct. ([Stroomindex](https://www.stroomindex.nl/stand/2026-10/), from search snippet)
- **TenneT will renew about 800 km of high-voltage lines**, for 30% more power. **Verified at headline level, 2026-10-16**: the TenneT news list ([tennet.eu/nl/nieuws](https://www.tennet.eu/nl/nieuws)) carries the item "TenneT vernieuwt 800 kilometer hoogspanningslijn voor 30 procent meer stroom", dated 13 Oct 2026 ([item](https://www.tennet.eu/nl/nieuws/tennet-vernieuwt-800-kilometer-hoogspanningslijn-voor-30-procent-meer-stroom)). The article body sat behind a bot challenge and was not read, so the time frame and exact scope (reconductoring versus other reinforcement) are unverified: quote only "800 km" and "30%" as TenneT's headline, nothing more. (Earlier secondary source: [Change Inc, 14 Oct](https://www.change.inc/transities/nieuwsupdate-financiele-problemen-voor-groene-staalfabriek-in-zweden-en-tennet-verzwaart-stroomnet).)
- **Enexis' build programme in Overijssel:** 7 new high-voltage stations, 31 extended and 150 new transport-distribution stations. Enexis is also running blackout drills. ([RTV Oost, 14 Oct](https://www.oost.nl/nieuws/3704153/stroomnet-is-betrouwbaar-toch-oefent-enexis-op-blackout-simuleren-hele-jaar-door), from search snippet)

### Why it matters for you
- **Flexibility is becoming a repeatable process.** The path is need, then request, then bid, then contract, then call-off. That is a value stream with a lead time, and Lean applies to it directly.
- **150 stations in one province only works with standard designs and standard work.** That is Enexis' standardisation lever from last week, now at scale.

### Actions
1. **Learn the GOPACS flow end to end:** the IDCONS, auction and CBC routes. Interview line: *"How long does it take from a published flex need to a signed contract, and where does it wait?"*
2. **Check the career pages directly** (werkenbij.enexis.nl, werkenbijstedin.nl, werkenbijalliander.com). Search engines surfaced no current CI roles.

### Notes digested
- None. The notes section was empty this week.

## Digest 2026-10-13 (an early edition, sent with the morning briefing)

### News this week
- **Autumn progress report on congestion (5 Oct 2026).**
  - The national congestion programme (LAN) and Netbeheer Nederland's *Stand van de Uitvoering* came out together.
  - The queue holds just over **15,000 requests**, and it is growing more slowly than in earlier years.
  - Since **1 Oct 2026**, municipalities can request grid capacity earlier for planned housing and schools.
  - Sources: [LAN update, autumn 2026](https://omgevingsweb.nl/wp-content/uploads/2026/10/108251533-Bijlage-Actualisatie-van-de-voortgang-LAN-najaar-2026.pdf), [Solar Magazine on the queue](https://solarmagazine.nl/nieuws-zonne-energie/i43390/wachtrij-stroomnet-groeit-naar-15-000-aanvragen-oplossing-stikstofproblematiek-in-zicht), [Omgevingsweb on housing](https://omgevingsweb.nl/nieuws/netcongestie-zet-woningbouw-verder-onder-druk-netbeheerders-en-provincies-roepen-om-ingrijpen-rijk/)
- **Congestion relievers waiting.**
  - 730 requests for priority as a *congestieverzachter* were registered by the end of June.
  - Most are still being assessed, because that category has the most complex review.
  - Source: [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i44987/honderden-partijen-die-voorrang-aanvragen-als-congestieverzachter-wachten-nog-op-groen-licht-door-complex-beoordelingsproces)
- **Connection terms for households, still open.**
  - The CBb ruled on 28 April 2026 (WoonFriesland/Liander).
  - The ACM's planned draft decision for small consumers, announced for summer 2026, has not been found yet.
  - The ACM still uses about 18–22 weeks as a reasonable term where digging is needed.
  - Sources: [ACM on the CBb ruling](https://www.acm.nl/nl/node/29102), [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i38855/rechter-verplicht-acm-tot-nieuw-besluit-over-aansluittermijn-consumenten)
- **Lean results in the field.**
  - Stedin cut the lead time for transformer stations **from nine to three months** through better cooperation with municipalities.
  - A new connection system lets a medium-voltage station be connected in one day instead of two.
  - Source: [IO+](https://ioplus.nl/en/posts/rising-electricity-demand-puts-stedins-grid-under-strain)

### Why it matters for you
- The sector's own reporting now talks about **queues, lead times and assessment processes**. That is flow language.
- The congestion-reliever backlog is a textbook case of a complex, unstandardised assessment step becoming the bottleneck.
- Stedin's 9 → 3 months is a lead-time result you can quote.

### Actions
1. **Read the LAN autumn update (about 20 minutes).** Pick one bottleneck from it to use as a talking point: where it waits, why, and the Lean move.
2. **Follow Netbeheer Nederland's *Stand van de Uitvoering*** and Stedin's operations news. Stedin is the operator talking most openly about lead-time reduction, so it is a good door to knock on.

### Notes digested (collected 2026-10-12)

#### Execution capacity is the sector's real bottleneck
- Netbeheer Nederland: a shortage of about **28,000 technicians up to 2029**. Stedin's CEO says the work package doubled in five years, with a retirement wave on top.
- Nov 2025 *Opschalingsplan 2030*: grid operators, contractors and government aim for **+5,000 technicians by 2030**, with €25M from the Klimaatfonds. The binding constraint is **training and mentoring capacity**, not recruitment.
- Why it matters for you: this is a classic Theory of Constraints / Lean case. When capacity can't be bought quickly, the gains come from flow, standard work, less rework and fewer wasted visits. That is exactly a CI lead's job.
- Sources: [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan), [Netbeheer Nederland, Stand van de uitvoering Q1 2025](https://www.netbeheernederland.nl/sites/default/files/2025-03/stand_van_de_uitvoering_q1_2025_1.pdf)

#### Standardisation is already Enexis' biggest lever
- Enexis moved substations (verdeelstations) from custom-built to **one standard design** with prefab skids (Siemens). Capacity went from about **10 to about 100 stations a year**, aiming at 800 in eight years.
- BAM launched a plug-and-play compact station (July 2026), claiming 75% shorter placement time.
- Why it matters for you: "standard work for standard jobs" is the most proven Lean move in this sector. It's a strong talking point and a credible entry for your consulting experience.
- Sources: [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i43650/gestandaardiseerde-aanpak-verdeelstations-versnelt-uitbreiding-elektriciteitsnet-enexis), [Siemens press release](https://press.siemens.com/nl/en/node/123), [Solar Magazine on BAM](https://solarmagazine.nl/nieuws-zonne-energie/i44390/bam-lanceert-stekkerbaar-stroomstation-en-verkort-plaatsingstijd-met-75-procent)

#### Congestion: the toolbox beyond "build more grid"
- More than **15,000 large-consumer requests** are in the regional queue (end of 2025, national).
- Instruments to know:
  - the **prioritisation framework** for societal projects, mandatory since 1 Oct 2024;
  - the **time-bound transport right** (≥85% of hours, about half the tariff; from 1 April 2025);
  - **non-firm ATO**;
  - the **capaciteitsbeperkingscontract (CBC)**;
  - **GOTORK** (use-it-or-lose-it for unused contracted capacity).
- Why it matters for you: these are capacity-allocation problems, not only engineering ones. Queue management, triage and flow thinking apply directly.
- Sources: [ACM overview of congestion measures](https://bouwstenen.nl/sites/default/files/uploads/overzicht-netcongestiemaatregelen-acm_0.pdf), [Solar Magazine on GOTORK](https://solarmagazine.nl/nieuws-zonne-energie/i35667/acm-publiceert-ontwerp-codebesluit-om-ongebruikte-transportcapaciteit-af-te-pakken)

#### Rules in motion
- **Energiewet** in force since 1 Jan 2026. The remaining ~500,000 analogue meters must be replaced (letters in 2026–2027). Net metering (*saldering*) ends 1 Jan 2027.
- **Connection terms:** the 18-week term (12 without digging) was annulled by the CBb in Sept 2024. The ACM plans a new draft decision for small consumers in 2026.
- **Nitrogen:** with the construction exemption gone, grid projects run months to years late. Liander reports more than 300 delayed projects in Gelderland, and an EU exemption is being negotiated.
- Sources: [Solar Magazine on old meters](https://solarmagazine.nl/nieuws-zonne-energie/i42697/einde-salderingsregeling-nog-500-000-oude-meters-moeten-verplicht-vervangen-last-onder-dwangsom-bij-weigering), [ACM on connections](https://www.acm.nl/nl/energie/elektriciteit-en-gas/netbeheer/aansluiting-op-elektriciteitsnet-en-gasnet), [Solar Magazine on nitrogen](https://solarmagazine.nl/nieuws-zonne-energie/i40627/stikstofregels-bedreigen-uitbreiding-stroomnet-gelderland-liander-vraagt-uitzonderingspositie)

#### Quieter problems worth knowing
- **Reliability:** 23.9 outage minutes per customer in 2024, 14.8% above the five-year average. 27,341 interruptions. ([Netbeheer Nederland](https://www.netbeheernederland.nl/sites/default/files/2025-04/03.02._betrouwbaarheid_van_elektriciteitsnetten_in_nederland_-_resultaten_2024.pdf))
- **Digging damage:** about 7% of digs in Brabant cause damage, 10.7% in Vught. ([Omroep Brabant](https://www.omroepbrabant.nl/nieuws/4454940/gaslekken-en-stroomuitval-graafwerkzaamheden-zorgen-voor-miljoenen-schade))
- **Inverters tripping:** solar inverters switch off above 253 V on the LS grid. Complaints tripled, and smart-meter data shows far more cases than complaints. ([Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i34795/3-keer-zo-veel-klachten-over-uitvallen-omvormers-zonnepanelen))
- **2G/3G sunset:** about 2.5 million first-generation smart meters with GPRS are being replaced in 2024–2029. Liander tendered €275M for 1.5M addresses. ([Gaslicht](https://www.gaslicht.com/energie-informatie/slimme-meter))
- **Power theft:** about 1 billion kWh a year, mostly cannabis farms. ([DutchNews](https://dutchnews.nl/2019/03/marijuana-growers-are-stealing-one-billion-kilowatts-of-electricity-a-year))

#### The management-system standard every Dutch grid operator works under
- **NTA 8120** sets the requirements for a safety, quality and capacity management system for electricity and gas grid operators, under Dutch law. It derives from PAS 55 and is now aligned with **ISO 55001** (asset management, 2023 edition).
- Certification follows Netbeheer Nederland's **NN-CAM 5.0** scheme, in force since 1 Sept 2024; only 5.0 is valid after 31 Dec 2025.
- Why it matters for you: asset management (ISO 55001 / NTA 8120) is the language grid operators run on, much as IATF or ISO 9001 is in manufacturing. Knowing how PDCA, risk-based decisions and continuous improvement are built into it gives you an instant bridge from Lean to this sector.
- Sources: [Netbeheer Nederland, NN-CAM 5.0](https://netbeheernederland.nl/sites/default/files/2024-10/nn-cam_versie_5.0.pdf), [Kiwa on PAS 55 and NTA 8120](https://www.kiwa.com/en/services/consultancy/pas55/)
