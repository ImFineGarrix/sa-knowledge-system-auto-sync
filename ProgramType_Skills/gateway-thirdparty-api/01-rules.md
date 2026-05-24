# 01 — Global Rules for Every Section

Read this file before writing any output file. These rules apply to both new project and existing project workflows.

## Output Folder Rule

Create one output folder per project inside `Projects/{product}/specs/`:

```text
Projects/{product}/specs/
  {project-name}/             Lowercase, hyphen-separated
    01-story.md
    02-requirements.md
    ...
    11-dev-handoff-issue.md
    _backup/                  Backups of overwritten files (created on demand)
```

- Never mix output with templates. Templates live under `template_document/`; generated artifacts live under `Projects/{product}/specs/`.
- If information is missing, make reasonable assumptions and record them in the relevant file. Do not block the workflow unless a missing decision makes the spec unsafe or impossible.

## Output Overwrite / Backup Rule

Before writing any file under `Projects/{product}/specs/{feature}/`, check whether the target file already exists.

If the file exists, do **not** silently overwrite. Ask the SA:

```text
ไฟล์เดิม `{filename}` พบอยู่แล้วใน Projects/{product}/specs/{feature}/
ต้องการ backup ไฟล์เดิมไว้ก่อนเขียนทับหรือไม่?
1. Backup แล้วเขียนทับ (recommended)
2. เขียนทับโดยไม่ backup
3. ยกเลิก / เลือกชื่อใหม่
```

If the SA chooses to backup, copy the existing file to:

```text
Projects/{product}/specs/{feature}/_backup/{filename}.{YYYYMMDD-HHmmss}.bak
```

Use the current timestamp in the form `YYYYMMDD-HHmmss` (e.g., `05-api-spec.md.20260514-143012.bak`). Create the `_backup/` folder if it does not exist. After the backup completes, proceed with the new write.

The backup rule applies to all artifacts in `Projects/{product}/specs/` including section files (01..12) and the final `11-dev-handoff-issue.md`.

## SA Decision Gate Rule

Before starting each section, ask the SA to choose:

1. Use the default template.
2. Customize the template or approach.
3. Skip this section with a reason.
4. Specify another approach when the offered options do not cover the need.

When the SA skips a section, record the skip reason in `11-dev-handoff-issue.md` under "Skipped / Not Applicable Artifacts". If a skipped section affects later sections, state the impact and continue with adjusted assumptions.

Do not silently generate every artifact. Treat each section as a checkpoint.

Use this short prompt pattern:

```text
Next section: {section name}
Default output: {file name}
Default approach: {brief template/approach summary}

Choose one:
1. Proceed with default
2. Customize
3. Skip / Not applicable
4. Specify another approach
```

If the SA chooses customize, ask only the minimum follow-up questions needed for that section.

## Organization Defaults

Use the defaults in `template_document/defaults/` as the first recommendation when they fit the project. Always ask the SA before applying them.

- API/auth/header defaults: `template_document/defaults/api-auth-defaults.md`
- Technology defaults: `template_document/defaults/technology-defaults.md`
- Architecture defaults: `template_document/defaults/architecture-defaults.md`
- Logging defaults: `template_document/defaults/logging-defaults.md`
- GitLab issue defaults: `template_document/defaults/gitlab-issue-defaults.md`
- Postman defaults: `template_document/defaults/postman-defaults.md`
- Partner HTML style defaults: `template_document/defaults/partner-html-style-defaults.md`
- Security / data protection defaults: `template_document/defaults/security-data-protection-defaults.md`

Prompt pattern:

```text
Organization default available:
{summarize the relevant default}

Choose one:
1. Use organization default
2. Customize
3. Skip / Not applicable
```

## Config Parameter Documentation Rule

When any configuration parameter, environment variable, feature flag, or application tag parameter is defined in any artifact, document all of the following for each parameter:

- **Name** — parameter key or variable name.
- **Purpose** — what this configuration controls.
- **Type and allowed values** — data type and valid options or range.
- **Effect** — what happens when each value is set (what changes in behavior).
- **Default** — default value when not explicitly set.

Do not define a config parameter without explaining its effect. A parameter list without effect descriptions is not a usable spec.

## Next Steps

After applying the global rules, load the workflow file for the chosen mode:

- New project → [`02-new-project.md`](02-new-project.md).
- Existing project (modify / bug fix / integration change) → [`03-existing-project.md`](03-existing-project.md).

Templates and the final quality gate are kept separate:

- Template paths → [`04-templates.md`](04-templates.md).
- Pre-finalize checklist → [`05-quality-gate.md`](05-quality-gate.md).
