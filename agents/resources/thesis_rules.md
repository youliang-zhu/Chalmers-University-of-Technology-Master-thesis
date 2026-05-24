# Chalmers Master's Thesis Rules And Evidence

Last researched: 2026-05-23.

This document summarizes the current Chalmers University of Technology rules,
procedures, and writing requirements relevant to this master's thesis project.
It is based on current Chalmers official pages and the official regulation PDF
downloaded into `agents/sources/`.

The most important source is:

- Local file: `agents/sources/chalmers-regulations-degree-projects-masters-theses-C2025-0611.pdf`
- Extracted text: `agents/sources/chalmers-regulations-degree-projects-masters-theses-C2025-0611.txt`
- Official URL: <https://www.chalmers.se/api/media/?url=https%3A%2F%2Fwebbpublicering360.portal.chalmers.se%2FExtern%2FHome%2FDownload%3Frecordnor%3D1064415%262025_10%261324019_1_1.PDF%26ex>
- Document: `Regulations for degree projects and Master's theses at first and second cycle levels at Chalmers`, reg. no. `C 2025-0611`
- Applies from: `1 September 2025`
- Decision: Vice President for Education, `20 August 2025`
- Replaces: `C 2024-1325`

## Critical Rules First

These are the rules that future agents must treat as hard constraints when
writing or configuring the thesis.

1. The thesis must be written in English.
   Evidence: Chalmers regulation `C 2025-0611`, section 8.2, states that the
   essay for a Master's thesis on MSc in Engineering, Master of Architecture,
   and Master's programmes must be written in English, except for programmes
   taught in Swedish.

2. The thesis must be public, both as a written report and as an oral
   presentation.
   Evidence: regulation `C 2025-0611`, section 7.6, says the degree project must
   be presented openly in writing and orally, and that the entire essay must be
   public.

3. Do not include confidential or proprietary information that cannot be made
   public.
   Evidence: Chalmers' IP/confidentiality page says the work must remain public
   enough for the examiner to approve it, and that examination material must
   always be public.

4. The final report must follow Chalmers formatting/template expectations.
   Evidence: regulation `C 2025-0611`, section 8.2, requires essays to be
   formatted according to Chalmers' template for degree projects. The "Design and
   publish Master's thesis" page also says the thesis should be produced as a
   PDF according to the templates.

5. The abstract must be 250-350 words and end with no more than 10 keywords.
   Evidence: Chalmers "Design and publish Master's thesis" page, Abstract
   section.

6. The thesis must pass plagiarism checking.
   Evidence: regulation `C 2025-0611`, section 8.2, says the examiner checks the
   essay against a plagiarism tool. Section 8.6 says plagiarism will not receive
   a pass and may lead to disciplinary measures.

7. AI tools may be used only according to examiner permission and must be used
   transparently and responsibly.
   Evidence: Chalmers' AI tools page says the examiner determines how and to
   what extent AI tools are allowed. The same page requires responsibility,
   transparency, and a description of how AI was used. Regulation `C 2025-0611`,
   section 8.6, ties AI-tool misuse to academic honesty and possible discipline.

8. For a 30-credit Master's thesis, a Pass requires at least High Quality for all
   learning objectives, and the required components must normally be completed
   within 30 working weeks.
   Evidence: regulation `C 2025-0611`, section 8.1.1.

9. To pass, the project requires more than a written report: approved planning
   report, approved presentation and defence, approved opposition of another
   project, attendance at two other presentations, and approved report.
   Evidence: regulation `C 2025-0611`, section 8.1.

10. The oral presentation must normally be at Chalmers, advertised by the
    department at least two weeks before the presentation date, last 45-60
    minutes, and include opposition/discussion for about one third of the time.
    Evidence: regulation `C 2025-0611`, section 8.3.

11. The final report must be completed before the oral presentation but not yet
    published, so presentation feedback can still be incorporated.
    Evidence: regulation `C 2025-0611`, section 8.3.

12. The thesis must be registered in Chalmers' e-publication system. Full-text
    e-publication can be declined, but registration/searchable metadata is
    mandatory.
    Evidence: regulation `C 2025-0611`, section 8.2, E-publication.

13. If personal data is used, it must be necessary, minimized, protected, and
    handled under GDPR and Chalmers guidance. Prefer anonymous data whenever it
    can achieve the goal.
    Evidence: Chalmers "Handling of personal data" page.

14. For this repository, final thesis writing should remain inside
    `paper/include/` and must compile with:

    ```bash
    cd /mnt/models/youliang/master_thesis/paper
    make pdf
    ```

## Practical Implications For This Thesis

This thesis is about NanoMem and long-term memory for LLM agents. The Chalmers
rules imply the following project-specific requirements:

- Keep the thesis self-contained and public. Do not include API keys, private
  datasets, private user data, or confidential company material.
- If using LLM-generated text, code, diagrams, or analysis during writing, record
  that use transparently. Add a thesis appendix or methodology note if the
  examiner requires it.
- Treat generated text as draft material only. The student remains responsible
  for verifying claims, citations, experiments, code descriptions, and results.
- Add a clear sustainability/ethics/societal-impact discussion, even if the
  conclusion is that some aspects are limited. The planning report and
  assessment criteria explicitly expect these aspects to be considered or
  justified.
- Keep Method, Results, Discussion, and Conclusion logically linked. The quality
  criteria emphasize problem formulation, method justification, critical
  evaluation, substantiated conclusions, and written structure.
- Use high-quality figures. For print-oriented material, prefer vector graphics
  for diagrams and ensure raster images are at least 300 dpi where relevant.
- Preserve a bibliography with complete references and use sparse, clearly
  marked direct quotations.

## Source Inventory

Downloaded local sources:

```text
agents/sources/chalmers-regulations-degree-projects-masters-theses-C2025-0611.pdf
agents/sources/chalmers-regulations-degree-projects-masters-theses-C2025-0611.txt
agents/sources/chalmers-master-thesis-page.html
agents/sources/chalmers-design-and-publish-master-thesis.html
agents/sources/chalmers-planning-report-public-defence.html
agents/sources/chalmers-regulations-use-of-ai-tools.html
agents/sources/chalmers-ip-patents-confidentiality.html
agents/sources/chalmers-handling-personal-data.html
agents/sources/chalmers-e-publication-and-printing.html
```

Official source URLs:

- Master thesis/Degree project: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/master-thesis/>
- Regulations PDF `C 2025-0611`: <https://www.chalmers.se/api/media/?url=https%3A%2F%2Fwebbpublicering360.portal.chalmers.se%2FExtern%2FHome%2FDownload%3Frecordnor%3D1064415%262025_10%261324019_1_1.PDF%26ex>
- Design and publish Master's thesis: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/master-thesis/design-and-publish-master-thesis/>
- Planning report and public defence: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/master-thesis/planning-report-and-public-defence-of-a-degree-project/>
- Regulations for the use of AI tools: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/regulations-for-the-use-of-ai-tools/>
- Intellectual property, patents and confidentiality: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/intellectual-property-patents-and-confidentiality/>
- Handling of personal data: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/handling-of-personal-data/>
- E-publication and printing: <https://www.chalmers.se/en/education/your-studies/masters-and-bachelors-thesis/master-thesis/e-publication-and-printing/>
- Chalmers Writing Guide, parts of a thesis/report: <https://writing.chalmers.se/chalmers-writing-guide/thesis-and-report-writing/parts-of-a-thesis-report/>

Recency of the main web pages at time of research:

- Master thesis/Degree project page: updated `22 April 2026`.
- Planning report and public defence page: updated `22 April 2026`.
- Design and publish Master's thesis page: updated `27 October 2025`.
- IP, patents and confidentiality page: updated `15 September 2025`.
- AI tools page: updated `18 December 2024`.
- Personal data page: updated `28 March 2024`.
- E-publication and printing page: updated `30 November 2023`.

## Official Regulation `C 2025-0611`

### Status And Applicability

The official regulation is the latest core rule file found in this research. It
applies from `1 September 2025`, applies until further notice, and replaces the
previous `C 2024-1325` regulation.

Use this PDF as the primary authority whenever a web page and the PDF overlap.

### Scope And Credits

For Chalmers MSc in Engineering, Master of Architecture, and Master's
programmes, the Master's thesis is a course of either 30 or 60 higher education
credits.

The regulation states that:

- For MSc in Engineering/Master of Architecture degrees, an independent project
  of at least 30 credits must be completed.
- For Master's degrees, the independent project is normally at least 30 credits
  within the main field of study, with a limited exception where a prior
  third-cycle independent project exists.

For this repository, assume the thesis is a 30-credit Master's thesis unless the
programme/examiner says otherwise.

### Purpose

The thesis must demonstrate deepened knowledge, understanding, skills, and
attitudes within the education. It should be carried out at the end of the
education and synthesize previously acquired knowledge.

For Master's theses, the regulation emphasizes technical/scientific/artistic
content and the student's ability to work independently as an engineer,
architect, or Master of Science.

### Examiner And Supervisor

The examiner:

- Is scientifically and qualitatively responsible for the degree project.
- Ensures learning objectives are met.
- Decides when the project can be approved.
- Decides the grade.

The supervisor:

- Provides scientific, technical, or artistic support.
- Assists with practical processes.

If the project is carried out in an external organization, there may also be an
external supervisor.

### Conditions For Starting

For students admitted only to a Master's programme, the regulation requires at
least 45 higher education credits before starting a degree project. Necessary
prerequisite courses for the specific project must also be completed. The
examiner formulates and verifies such prerequisites.

For MSc in Engineering/Master of Architecture, the listed threshold is at least
225 higher education credits.

### Project Initiation And Application

A project may be initiated by:

- The student contacting a company or department with a proposal, while also
  contacting an examiner or departmental degree-project contact.
- A proposal from a company or department on the Chalmers thesis portal.

The student must prepare a brief written project description with enough
information for the examiner to judge whether the task is suitable. It should
include background, purpose, objectives, and possibly methods.

The thesis application form or exemption form must be digitally approved by the
examiner and the Director of Master's Programme / Head of Programme where
required.

### Planning Report And Risk Assessment

The planning report must specify the problem description/task. It must include:

- Background.
- Preliminary purpose.
- Objectives.
- Limitations.
- Method.
- Timetable for implementation.

The planning report must address societal, ethical, and ecological aspects that
need to be considered according to the learning objectives. If they are not
considered, the report must explain why.

All degree projects must be risk assessed using the Simple risk assessment
template. The student carries out the risk assessment with the examiner and any
external supervisor. The risk assessment must be attached to the planning report
and approved by the examiner.

### Supervision

Students are entitled to regular supervision and other resources needed for
implementation. Supervision can come from Chalmers supervisors and, where
applicable, external supervisors.

### Interim Presentations

The regulation has special interim-presentation requirements for 60-credit
projects, Architecture, and some other programmes. For a normal 30-credit
Master's thesis in this repository, no generic 30-credit interim presentation
requirement was found in the core regulation. Check the specific programme
course syllabus and Canvas page.

### Public Access And Confidentiality

The degree project must be presented openly in writing and orally. The entire
essay must be public. This also applies if the essay is not fully published.

Consequences for this thesis:

- Do not include secret or confidential material that is required to understand
  or assess the thesis.
- If collaboration material is sensitive, keep it outside the thesis or
  anonymize/summarize it in a way that remains assessable and public.
- Make sure the examiner can approve the work without access to non-public
  attachments.

### Copyright

The student author owns copyright in the work. Copyright includes economic and
moral rights. The student may transfer economic rights by agreement, but should
not sign agreements that prevent public disclosure of the thesis, because the
work must be assessable and public.

### Grades And Components Required To Pass

For Master's theses on MSc in Engineering, Master of Architecture, and Master's
programmes, grades are normally on the UG scale:

- `U`: Fail
- `G`: Pass

To pass, the following are required:

- Approved planning report.
- Approved presentation and defence.
- Approved opposition of another degree project.
- Attendance at two other presentations.
- Approved report under prevailing standards for scientific and technical
  reporting.

For a 30-credit thesis, Pass requires at least High Quality for all learning
objectives. For learning objective 5, the student must have passed all listed
components within a total time frame of 30 working weeks. The examiner may, for
special reasons, extend this by 10 working weeks at a time.

### Written Presentation

Rules:

- The Master's thesis must be written in English, except for Master's programmes
  taught in Swedish.
- It must follow the Chalmers template for formatting degree projects.
- If two students perform a project together, the division of labour must be
  clearly outlined in a separate contribution report.
- The report must give the examiner sufficient basis to decide the grade.
- The examiner checks the report using a plagiarism tool.

For this repository:

- Keep English as the final language.
- Keep Chalmers template structure.
- Use `paper/Main.tex` and chapter files under `paper/include/`.
- Make every technical claim traceable to literature, code, experiments, or
  clearly marked reasoning.

### E-Publication

Chalmers degree projects must be registered and published electronically in
Chalmers' e-publication system. They become searchable in Student Theses and
available online if full-text publication is approved.

The student may decline electronic publishing of the full text, but registration
with searchable metadata is mandatory. Full-text electronic publication requires
all authors to sign and approve the publication agreement on the work card.

### Oral Presentation

Rules from section 8.3:

- At the time of oral presentation, the essay must be completed but not yet
  published.
- The oral presentation, including opposition, must take place at Chalmers unless
  an exceptional case is approved by the examiner.
- If not on site, it must be streamed digitally and open to the public.
- The presentation should be advertised at the relevant department at least two
  weeks before the presentation date.
- It should normally occur between 15 August and 15 June during normal working
  hours.
- The presentation begins with the student presenting the project, followed by
  opposition and discussion.
- Total duration should be 45-60 minutes, with about one third for opposition
  and discussion.
- For Master's theses, the oral presentation must be in English unless an
  exception is granted for a Swedish-taught programme.

### Opposition

The student must participate as an opponent for another degree project.

Rules:

- The department decides how opposition is organized.
- At most two students may act as opponents for the same project.
- Opponents have 10 minutes, and should use all of it.
- Opponents must review the essay.
- Linguistic errors and minor remarks must be written down and submitted after
  the opposition.
- The examiner for the presented project assesses and signs off the opposition.
- The student appoints opponent(s) for their own project, unless programme rules
  say otherwise.

### Attendance At Other Presentations

The student must attend two other degree-project presentations. The examiner of
the presented project signs approved attendance on the work card.

### AI Tools And Academic Honesty

The regulation states that students are responsible for following Chalmers'
guiding principles and rules regarding academic honesty and AI tools. An essay
containing plagiarism cannot pass. If the essay violates AI-tool or academic
honesty rules, disciplinary measures may follow.

For this repository, record AI assistance transparently. Do not let an LLM invent
citations, experiment numbers, results, or source claims.

## Assessment Criteria For Master's Theses

Appendix 1 of `C 2025-0611` gives guiding principles for quality assessment of
Master's theses. These criteria should guide every chapter.

### Knowledge And Relation To Current Research

High Quality requires:

- Significant specialization in the main field.
- Use of advanced-level knowledge.
- A written literature review.
- Reflection on how the thesis connects to the forefront of knowledge.

Very High Quality adds:

- Extensive review of existing literature.
- Clear contribution to new knowledge.
- Independent contribution to the field.

Writing implication: the Theory/Background chapter must do more than list
papers. It must explain how NanoMem relates to current agent-memory, retrieval,
temporal reasoning, and evidence-synthesis research.

### Method Choice And Justification

High Quality requires identification of relevant theories/methods, justified
choice of theory/method, and correct application.

Writing implication: the Method chapter must justify why a Planner-Synthesizer
loop, event schema, verdict mechanism, temporal grounding, and reward design are
appropriate for the problem.

### Contribution To Research And Development

The contribution to research and development work must be clearly presented.

Writing implication: the thesis should explicitly state what is new compared
with Mem0, A-MEM, MemSifter, Memory-T1, Memory-R1, MemR3, SUMER, RAG-style
memory, and related systems.

### Problem Formulation And Conclusions

High/Very High Quality emphasizes:

- Clear objectives or questions.
- Adequate, critical, reflective processing.
- Clear links between questions/objectives, results, discussion, and
  conclusions.
- Well-substantiated conclusions.

Writing implication: the Introduction must define research questions, and the
Results/Discussion/Conclusion must answer them directly.

### Planning And Execution

High Quality requires a realistic plan, adherence to communicated deadlines, and
documentation/communication of necessary adjustments.

Writing implication: the thesis can briefly document the project process and
scope changes where relevant, but the report itself should focus on the
scientific method and results rather than becoming a diary.

### Technical Solutions And Critical Evaluation

High Quality requires developed solutions that are critically analysed and
evaluated. Very High Quality expects alternative solutions to be developed and
processed in a relevant and exhaustive way.

Writing implication: include ablations, alternatives considered, error analysis,
and failure cases.

### Integration Of Knowledge

High Quality requires relevant knowledge and methods to be acquired and applied.
Very High Quality expects innovative integration from several subjects.

Writing implication: connect LLM agents, memory systems, retrieval, temporal
reasoning, structured evidence, benchmark construction, and reinforcement
learning or reward design where applicable.

### Written And Oral Presentation

High Quality requires accurate language and good coherence, structure, and
layout. Very High Quality requires a very well-written essay with very high
overall coherence, structure, and layout.

Writing implication: keep chapters coherent, avoid conference-paper compression,
define terms before use, and ensure figures/tables directly support the text.

### Societal, Ethical, Ecological, And Sustainability Aspects

The criteria require relevant societal, ethical, and ecological aspects to be
identified and discussed. The planning report must justify if such aspects are
not considered.

For NanoMem, likely topics include:

- Privacy risks in long-term conversational memory.
- Faithfulness and hallucination risks in synthesized memory evidence.
- User consent and data retention.
- Safety of agent memory systems that influence downstream decisions.
- Environmental cost of training/evaluating LLM memory systems.
- Benchmark data provenance and synthetic data limitations.

### Ethical Aspects Of Research And Development

High Quality requires presenting possible ethical consequences of the performed
work.

Writing implication: add a dedicated ethics/limitations subsection, probably in
Discussion or Conclusion, and refer to privacy and AI-generated evidence risks.

### Independence

High Quality means the thesis was carried out with reasonable support. Very High
Quality means independent implementation without extraordinary support or
significant extra resources.

Writing implication: where relevant, clarify what the student implemented,
evaluated, and wrote, especially if source work was part of a larger research
project.

## Chalmers Design And Formatting Requirements

Source: "Design and publish Master's thesis", updated `27 October 2025`.

### PDF And Template

Student theses are registered in the Chalmers publication library and most are
published electronically. Theses should be produced as PDF files according to
Chalmers templates, including for e-publishing.

For this repository:

```bash
cd /mnt/models/youliang/master_thesis/paper
make pdf
```

Final generated file:

```text
paper/build/Main.pdf
```

### Standard Cover

The front cover should include:

- Title, not too long, describing the contents well.
- Subtitle, if used.
- Author's first and last name.
- Department or equivalent.
- Chalmers University of Technology.
- Place of publication, Gothenburg/Göteborg, Sweden, and year.
- Optional illustration/photo symbolizing the content. Its caption is printed on
  the imprint page.

### Title Page

The first page after the frontispiece should include:

- Report title.
- Any subtitle.
- Author's first and last name.
- Series name, if applicable.
- Report serial number, if applicable.

### Imprint Page

The imprint page should include searchable/bibliographic metadata:

- Title.
- Author.
- Copyright line with author's first and last name and year.
- Series name, serial number, ISSN, if applicable.
- Address/order information, if applicable.
- Name of printing firm or department.
- Place and year.

It should also include the sentence that acknowledgements, dedications, and
similar personal statements reflect the author's own views.

### Abstract

The abstract page requirements:

- Master-level abstract should be in English.
- Concise, between 250 and 350 words.
- Summarize the work's essential problem, methods, and results.
- Follow international standards in the subject area.
- End with at most 10 keywords for database searching.

For this thesis, write the abstract only after Method/Results/Discussion are
stable.

### Table Of Contents

The table of contents should provide a clear overview of the thesis contents and
disposition.

### Pagination And Printing

Chalmers printing guidance says pages should use A4 format and correct page
numbering, with odd pages on the right-hand side. Roman numerals for front
matter and Arabic numbering beginning with the first chapter are recommended.

The current Chalmers LaTeX template already follows this pattern.

### Images

For print:

- Photos/scanned paintings should be 300 ppi at final printed size.
- Line drawings should be high-resolution; EPS is suitable.
- Vector illustrations should not be converted to pixel graphics.
- Avoid low-resolution web-optimized images.
- Monochrome images should be grayscale, not RGB.

For this thesis:

- Prefer PDF/SVG/EPS/vector diagrams for architecture and pipeline figures.
- Keep bitmap screenshots only when necessary and use high resolution.

## Planning Report And Public Defence Page

Source: "Planning report and Public defence of a degree project", updated
`22 April 2026`.

The Chalmers page repeats and expands the regulation:

- Planning report must include background, preliminary purpose, objectives,
  limitations and method, and timetable.
- Societal, ethical, and ecological aspects must be highlighted or explicitly
  justified as not considered.
- All degree projects require risk assessment using the Simple risk assessment
  template.
- The risk assessment must be attached to the planning report and approved by
  the examiner.
- For a degree project to pass, the student must serve as an external reviewer
  on another degree project.
- The defence is an oral dialogue between author and reviewer.
- The final defence should critically review both content and formal written
  aspects.

The same page gives a useful planning-report structure:

- Introduction.
- Background.
- Aim.
- Limitations.
- Specification of the investigated issue.
- Methodology.
- Schedule, preferably as a Gantt chart.

This is mainly relevant if writing a separate planning report, but it also helps
shape the thesis Introduction and Method chapters.

## AI Tool Rules

Source: "Regulations for the use of AI tools in thesis work", updated
`18 December 2024`.

Key points:

- The examiner determines how and to what extent AI tools may be used.
- The decision can vary between theses, even with the same examiner.
- AI tools may be permitted for text, code, data analysis, or similar tasks, but
  only if used responsibly and transparently.
- The student assumes full responsibility for the work and must be able to
  justify content choices and defend AI's role in the thesis.
- Avoid over-reliance. Do not uncritically accept AI-generated rewrites, code,
  literature reviews, or data analyses.
- Be aware of plagiarism and copyright risks.
- At minimum, provide a description of how and to what extent AI tools were used.
- If AI-generated content appears in the thesis, it should be cited like other
  work.
- Protect sensitive or proprietary information; do not share it with AI tools
  without permission.
- Consult the Chalmers supervisor or relevant collaborators if uncertain,
  especially about privacy and ethics.

For this repository:

- Keep an internal record of AI assistance in `agents/`.
- Before final submission, ask the examiner whether an AI-use appendix,
  acknowledgement, or methodology note is required.
- Do not expose confidential paths, API keys, private data, or unpublished
  collaborators' information to external AI systems.

## Intellectual Property, Patents, And Confidentiality

Source: "Intellectual property, patents and confidentiality", updated
`15 September 2025`.

Key points:

- Students generally have rights to the results they produce unless they sign an
  agreement transferring rights.
- IP and confidentiality issues should be discussed among student/project team,
  supervisor, and company/organisation.
- NDA/confidentiality agreements may be relevant, but students must not waive
  the right to disclose results needed for examination.
- The student must have the right to disclose results publicly so the examiner
  can approve the work.
- Reports and project results are public documents at Chalmers when completed or
  submitted.
- Material forming the basis of examination must always be public.
- Public presentations are public events in practice, so sensitive information
  should be avoided.
- Patentable inventions should be protected before public presentation if
  relevant.

For this thesis:

- Keep the thesis public and reproducible at a level appropriate for assessment.
- If any NanoMem artifact is not public, describe it only in a non-confidential
  way or ask the examiner for guidance.

## Personal Data Rules

Source: "Handling of personal data", updated `28 March 2024`.

The page frames GDPR and Swedish data protection legislation as the basis for
personal data processing at Chalmers. Personal data includes any information
that can be directly or indirectly linked to a specific individual.

Examples include:

- Name.
- Address.
- Email.
- Picture or video.
- Social security number.
- ID number.
- IP address.
- Location information.
- User behavior.
- Survey opinions.
- Health data.
- Nationality.

Core principles:

- Transparency.
- Purpose limitation.
- Data minimization.
- Correctness.
- Security.
- Storage minimization.

Key practical rule: if the project goal can be achieved with anonymous data, use
anonymous data instead of personal data.

Checklist themes:

- Clarify actual need for personal data.
- Document purpose of processing.
- Discuss need and purpose with supervisor.
- Clarify responsibility with internship/company supervisor if applicable.
- Do not process sensitive personal data.
- Store data securely in Chalmers-approved storage.
- Protect personal data from others.
- Contact Chalmers' data protection officer when transferring personal data
  outside the EU/EEA.
- Use Chalmers' consent form if consent is needed.

For NanoMem:

- Long-term memory research often involves conversational histories. Treat any
  real conversation logs as personal data unless fully anonymized and
  unlinkable.
- Synthetic or public benchmark data is preferable for thesis examples.
- Do not include identifiable user sessions in the thesis.

## E-Publication And Printing

Source: "E-publication and printing", updated `30 November 2023`, and `C
2025-0611`, section 8.2.

The regulation is the primary source for publication obligation:

- Registration in the Chalmers e-publication system is mandatory.
- Full-text publication requires author approval.
- Departments handle registration and e-publication.
- The examiner is responsible for ensuring registration/publication is done.

The e-publication page adds practical print requirements:

- If printed, deliver a PDF according to the templates.
- Images must be at least 300 dpi for print.
- Black-and-white images must be grayscale.
- RGB is for screen display, not printing.

## Chalmers Writing Guide

Source: "Parts of a thesis / report", Chalmers Writing Guide.

The Writing Guide says thesis structure varies by department and field, and
students should check department guidelines, ask the supervisor, and look at
examples in the Chalmers Library.

It presents IMRAD as the basic scientific structure:

- Introduction: why the study was undertaken; research question, hypothesis, or
  purpose.
- Methods: when, where, and how the study was done.
- Results: what answer or findings were obtained.
- Discussion: what the answer implies, why it matters, and how it relates to
  other work.

For this thesis, the current Chalmers template chapters can be mapped as:

- `Introduction`: problem, motivation, research questions, contributions.
- `Theory`: background and related work.
- `Methods`: NanoMem method, system design, training/evaluation setup.
- `Results`: experiments, ablations, case studies.
- `Conclusion`: discussion, limitations, ethics/societal aspects, future work.

If needed, add a separate `Discussion.tex` later, because a Master's thesis often
benefits from explicit discussion rather than merging all interpretation into
Results or Conclusion.

## Required Thesis Checklist For This Repository

Before final submission, verify:

- [ ] `paper/include/settings/Settings.tex` uses `\ThesisType{M}`.
- [ ] Title page contains real title, author name, department, programme,
      supervisor, examiner, place, and year.
- [ ] Abstract is 250-350 words.
- [ ] Abstract ends with no more than 10 keywords.
- [ ] The thesis is written in English.
- [ ] All figures and tables are referenced and readable.
- [ ] References are complete and all in-text citations appear in the
      bibliography.
- [ ] Direct quotations are sparse and clearly marked.
- [ ] AI tool use is documented according to examiner instructions.
- [ ] No confidential or non-public information is required to assess the work.
- [ ] No personal data appears unless necessary, lawful, minimized, and approved.
- [ ] Societal, ethical, ecological, and sustainability aspects are discussed or
      explicitly justified.
- [ ] Method and results are separate enough for scientific assessment.
- [ ] Conclusions directly answer the research questions/objectives.
- [ ] `make pdf` succeeds.
- [ ] The final PDF is checked visually.
- [ ] The thesis is ready for plagiarism checking.
- [ ] Oral presentation is scheduled and advertised through the department at
      least two weeks in advance.
- [ ] Opposition of another thesis is completed and signed.
- [ ] Attendance at two other presentations is completed and signed.
- [ ] Work card / e-publication agreement is handled according to department
      procedure.

## Evidence Notes For Future Agents

When future agents modify thesis content, use these authority levels:

1. `C 2025-0611` official regulation PDF: highest priority for rules.
2. Current Chalmers thesis pages: procedures, templates, publication, AI, IP,
   data handling.
3. Programme-specific Canvas/course syllabus/examiner instructions: may add
   local requirements. These were not accessible from this public web research.
4. Chalmers Writing Guide: writing advice, not a strict regulation unless
   referenced by examiner/programme.

If a rule is unclear or conflicts with examiner instructions, ask the examiner
or supervisor and record the answer in `agents/`.
