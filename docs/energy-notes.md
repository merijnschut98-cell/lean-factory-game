# Energy-sector notes for Merijn

Running notes on the Dutch energy sector, collected while researching *Spanning*. Every Friday they are turned into a short digest focused on what matters for a Lean / CI consultant who wants to work in the sector. Digested notes move into a dated section below.

Sources were read through search-engine extracts (this environment blocks direct access to most news sites); verify before quoting them in a conversation.

## This week (from 2026-10-12)

### Execution capacity is the sector's real bottleneck
- Netbeheer Nederland: a shortage of about **28,000 technicians up to 2029**. Stedin's CEO says the work package doubled in five years, with a retirement wave on top.
- Nov 2025 *Opschalingsplan 2030*: grid operators, contractors and government aim for **+5,000 technicians by 2030**, with €25M from the Klimaatfonds. The binding constraint is **training and mentoring capacity**, not recruitment.
- Why it matters for you: this is a classic Theory of Constraints / Lean case. When capacity can't be bought quickly, the gains come from flow, standard work, less rework and fewer wasted visits. That is exactly a CI lead's job.
- Sources: [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i42206/netbeheerders-en-aannemers-werven-5-000-extra-technici-via-opschalingsplan), [Netbeheer Nederland, Stand van de uitvoering Q1 2025](https://www.netbeheernederland.nl/sites/default/files/2025-03/stand_van_de_uitvoering_q1_2025_1.pdf)

### Standardisation is already Enexis' biggest lever
- Enexis moved substations (verdeelstations) from custom-built to **one standard design** with prefab skids (Siemens). Capacity went from about **10 to about 100 stations a year**, aiming at 800 in eight years.
- BAM launched a plug-and-play compact station (July 2026), claiming 75% shorter placement time.
- Why it matters for you: "standard work for standard jobs" is the most proven Lean move in this sector. It's a strong talking point and a credible entry for your consulting experience.
- Sources: [Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i43650/gestandaardiseerde-aanpak-verdeelstations-versnelt-uitbreiding-elektriciteitsnet-enexis), [Siemens press release](https://press.siemens.com/nl/en/node/123), [Solar Magazine on BAM](https://solarmagazine.nl/nieuws-zonne-energie/i44390/bam-lanceert-stekkerbaar-stroomstation-en-verkort-plaatsingstijd-met-75-procent)

### Congestion: the toolbox beyond "build more grid"
- More than **15,000 large-consumer requests** are in the regional queue (end of 2025, national).
- Instruments to know:
  - the **prioritisation framework** for societal projects, mandatory since 1 Oct 2024;
  - the **time-bound transport right** (≥85% of hours, about half the tariff; from 1 April 2025);
  - **non-firm ATO**;
  - the **capaciteitsbeperkingscontract (CBC)**;
  - **GOTORK** (use-it-or-lose-it for unused contracted capacity).
- Why it matters for you: these are capacity-allocation problems, not only engineering ones. Queue management, triage and flow thinking apply directly.
- Sources: [ACM overview of congestion measures](https://bouwstenen.nl/sites/default/files/uploads/overzicht-netcongestiemaatregelen-acm_0.pdf), [Solar Magazine on GOTORK](https://solarmagazine.nl/nieuws-zonne-energie/i35667/acm-publiceert-ontwerp-codebesluit-om-ongebruikte-transportcapaciteit-af-te-pakken)

### Rules in motion
- **Energiewet** in force since 1 Jan 2026. The remaining ~500,000 analogue meters must be replaced (letters in 2026–2027). Net metering (*saldering*) ends 1 Jan 2027.
- **Connection terms:** the 18-week term (12 without digging) was annulled by the CBb in Sept 2024. The ACM plans a new draft decision for small consumers in 2026.
- **Nitrogen:** with the construction exemption gone, grid projects run months to years late. Liander reports more than 300 delayed projects in Gelderland, and an EU exemption is being negotiated.
- Sources: [Solar Magazine on old meters](https://solarmagazine.nl/nieuws-zonne-energie/i42697/einde-salderingsregeling-nog-500-000-oude-meters-moeten-verplicht-vervangen-last-onder-dwangsom-bij-weigering), [ACM on connections](https://www.acm.nl/nl/energie/elektriciteit-en-gas/netbeheer/aansluiting-op-elektriciteitsnet-en-gasnet), [Solar Magazine on nitrogen](https://solarmagazine.nl/nieuws-zonne-energie/i40627/stikstofregels-bedreigen-uitbreiding-stroomnet-gelderland-liander-vraagt-uitzonderingspositie)

### Quieter problems worth knowing
- **Reliability:** 23.9 outage minutes per customer in 2024, 14.8% above the five-year average. 27,341 interruptions. ([Netbeheer Nederland](https://www.netbeheernederland.nl/sites/default/files/2025-04/03.02._betrouwbaarheid_van_elektriciteitsnetten_in_nederland_-_resultaten_2024.pdf))
- **Digging damage:** about 7% of digs in Brabant cause damage, 10.7% in Vught. ([Omroep Brabant](https://www.omroepbrabant.nl/nieuws/4454940/gaslekken-en-stroomuitval-graafwerkzaamheden-zorgen-voor-miljoenen-schade))
- **Inverters tripping:** solar inverters switch off above 253 V on the LS grid. Complaints tripled, and smart-meter data shows far more cases than complaints. ([Solar Magazine](https://solarmagazine.nl/nieuws-zonne-energie/i34795/3-keer-zo-veel-klachten-over-uitvallen-omvormers-zonnepanelen))
- **2G/3G sunset:** about 2.5 million first-generation smart meters with GPRS are being replaced in 2024–2029. Liander tendered €275M for 1.5M addresses. ([Gaslicht](https://www.gaslicht.com/energie-informatie/slimme-meter))
- **Power theft:** about 1 billion kWh a year, mostly cannabis farms. ([DutchNews](https://dutchnews.nl/2019/03/marijuana-growers-are-stealing-one-billion-kilowatts-of-electricity-a-year))

### The management-system standard every Dutch grid operator works under
- **NTA 8120** sets the requirements for a safety, quality and capacity management system for electricity and gas grid operators, under Dutch law. It derives from PAS 55 and is now aligned with **ISO 55001** (asset management, 2023 edition).
- Certification follows Netbeheer Nederland's **NN-CAM 5.0** scheme, in force since 1 Sept 2024; only 5.0 is valid after 31 Dec 2025.
- Why it matters for you: asset management (ISO 55001 / NTA 8120) is the language grid operators run on, much as IATF or ISO 9001 is in manufacturing. Knowing how PDCA, risk-based decisions and continuous improvement are built into it gives you an instant bridge from Lean to this sector.
- Sources: [Netbeheer Nederland, NN-CAM 5.0](https://netbeheernederland.nl/sites/default/files/2024-10/nn-cam_versie_5.0.pdf), [Kiwa on PAS 55 and NTA 8120](https://www.kiwa.com/en/services/consultancy/pas55/)
