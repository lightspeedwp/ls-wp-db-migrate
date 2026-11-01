# Assets & Media

Diagrams, templates, screenshots, and other media files for the WordPress Database Migration skill and documentation.

## Folder Structure

````bash
assets/
├── README.md              # This file
├── diagrams/              # Architecture and workflow diagrams
├── screenshots/           # UI screenshots and examples
├── templates/             # Configuration templates
└── media/                 # Logos, icons, and other media
```bash

## Usage Guidelines

### Diagrams
Store architecture diagrams, workflow flowcharts, and database schema visualizations here.

**Formats:**
- SVG (preferred for scalability)
- PNG (for screenshots and finished renders)
- Mermaid/PlantUML source (for version control)

### Screenshots
Store user interface screenshots and examples of tool usage.

**Formats:**
- PNG (preferred)
- JPG (for photographs)
- Avoid GIF (prefer short video clips instead)

### Templates
Configuration templates, example files, and starter templates for users.

**Includes:**
- `.env` example files
- YAML/JSON configuration templates
- Database schema templates
- Setup checklists

### Media
Logos, icons, badges, and brand assets.

**Includes:**
- Project logos
- GitHub badges
- Social media graphics
- Documentation icons

## Adding Assets

1. **Organize by type** — Use subfolders for diagrams, screenshots, templates, etc.
2. **Use descriptive names** — `database-migration-workflow.svg` not `diagram1.svg`
3. **Include metadata** — Add alt text and descriptions in documentation
4. **Version control** — Keep source files (SVG, source code) in git
5. **Document usage** — Link assets in relevant documentation files

## Asset Naming Convention

```bash
{type}-{description}-{version}.{ext}

Examples:
- workflow-migration-process-v1.svg
- screenshot-preflight-check-v2.png
- template-env-example.txt
- logo-wp-db-migrate.svg
```bash

## Embedding Assets in Documentation

### In Markdown

```markdown
![Alt text description](../assets/diagrams/workflow.svg)

Or with dimensions:
![Alt text](../assets/screenshots/example.png){width=400}
```bash

### Linking to Assets

```markdown
[Download template](../assets/templates/config-example.yml)
```bash

## Performance Considerations

- **SVG**: Use for scalable diagrams and icons
- **PNG**: Optimize with tools like `pngquant` or `imagemin`
- **Compression**: Run image optimization before committing
- **Size Limits**: Keep individual assets under 1MB

## Asset Maintenance

- Review assets quarterly for accuracy
- Update screenshots when UI changes
- Keep template files in sync with code
- Remove outdated or unused assets

## Related Files

- [Main README](../README.md) — Project overview
- [Documentation Index](../README.md) — Documentation guide
- [References](../README.md) — External resources

---

**Note:** All assets should align with the project's branding and style guidelines. See the main README for project branding information.
````
