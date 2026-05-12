# Synapse Python Client Skill

## Overview
The Synapse Python client (`synapseclient`) is the official Python SDK and CLI for Synapse (synapse.org), a collaborative biomedical data sharing platform by Sage Bionetworks. The modern `synapseclient.models` API provides async-first dataclass models with auto-generated sync wrappers.

## Installation
```bash
pip install synapseclient

# With optional extras
pip install "synapseclient[boto3,pandas,pysftp,curator]"
```

**Requires**: Python 3.10 - 3.14

## Authentication
```python
import synapseclient

# Personal access token (preferred)
synapseclient.login(authToken="your_token")

# From ~/.synapseConfig [default] profile
synapseclient.login()

# From environment variable SYNAPSE_AUTH_TOKEN
synapseclient.login()

# Select a named profile from ~/.synapseConfig
# Set SYNAPSE_PROFILE=myprofile or pass profile="myprofile"
synapseclient.login(profile="myprofile")
```

Auth priority chain: login args > config file (~/.synapseConfig) > SYNAPSE_AUTH_TOKEN env var > AWS SSM (via SYNAPSE_TOKEN_AWS_SSM_PARAMETER_NAME).

## Core Concepts
- **Entity**: Base class for Synapse objects (Projects, Folders, Files, Tables, Datasets, etc.)
- **Synapse ID**: Format `syn123456` - unique identifier for every entity
- **Async-first**: All model methods are async with `_async` suffix. The `@async_to_sync` decorator auto-generates sync wrappers (without the suffix)
- **Dataclass models**: All models are `@dataclass` classes (NOT Pydantic)

## Sync vs Async Usage

### Sync (default for scripts)
```python
from synapseclient.models import File
file = File(id="syn123456").get()           # sync wrapper
file.store()                                 # sync wrapper
```

### Async (for heavy I/O, parallel operations)
```python
import asyncio
from synapseclient.models import File

async def main():
    file = await File(id="syn123456").get_async()
    await file.store_async()

    # Parallel uploads
    files = [File(path=p, parent_id="syn123") for p in paths]
    await asyncio.gather(*(f.store_async() for f in files))

asyncio.run(main())
```

**Python 3.14+ note**: Calling sync wrappers from an active event loop raises `RuntimeError`. Use `await method_async()` explicitly in async contexts and Jupyter notebooks.

## Common Operations

### Upload a File
```python
from synapseclient.models import File

file = File(
    path="/local/path/file.csv",
    parent_id="syn123456",
    name="my_file.csv",
    description="Optional description"
).store()
print(file.id)  # syn ID of uploaded file
```

### Download a File
```python
from synapseclient.models import File

# Download to current directory
file = File(id="syn123456").get()
# file.path -> local path to downloaded file

# Download to specific directory
file = File(id="syn123456", path="/download/directory").get()

# Get metadata only (no download)
file = File(id="syn123456", download_file=False).get()
```

### Projects and Folders
```python
from synapseclient.models import Project, Folder

# Create a project
project = Project(
    name="My Project",
    description="Project description",
    annotations={"key": ["value"]}
).store()

# Create a folder
folder = Folder(
    name="Data",
    parent_id=project.id
).store()

# Retrieve metadata
project = Project(id="syn123456").get()
folder = Folder(id="syn789012").get()
```

### Annotations
```python
from synapseclient.models import File

# Add annotations during creation
file = File(
    path="/path/to/file.csv",
    parent_id="syn123456",
    annotations={
        "tissue": ["brain"],
        "assay": ["RNAseq"],
        "batch": [1, 2, 3]
    }
).store()

# Update annotations on existing entity
file = File(id="syn123456", download_file=False).get()
file.annotations = {"tissue": ["brain"], "assay": ["RNAseq"]}
file.store()
```

All annotation values must be lists (e.g., `{"key": ["value"]}`). Supports: strings, integers, floats, booleans, dates, datetimes.

### Working with Tables
```python
from synapseclient.models import Table, Column, ColumnType

# Query a table
df = Table.query(query="SELECT * FROM syn123456")

# Create a new table
columns = [
    Column(name="name", column_type=ColumnType.STRING),
    Column(name="age", column_type=ColumnType.INTEGER),
    Column(name="score", column_type=ColumnType.DOUBLE)
]

table = Table(
    name="my_table",
    parent_id="syn123456",
    columns=columns
).store()

# Store rows from CSV or DataFrame
table.store_rows(values="/path/to/data.csv")
```

### Datasets
```python
from synapseclient.models import Dataset, EntityRef, File

# Create a dataset with entity references
dataset = Dataset(
    name="My Dataset",
    parent_id="syn123456",
    columns=[Column(name="col1", column_type=ColumnType.STRING)]
)

# Add items (files/folders) to the dataset
dataset.add_item(EntityRef(id="syn111", version=1))
dataset.add_item(File(id="syn222"))
dataset.store()

# Create a snapshot version
dataset.snapshot(comment="v1 release", label="1.0")
```

### Entity Views
```python
from synapseclient.models import EntityView, ViewTypeMask

# Create a file view over a project scope
view = EntityView(
    name="My File View",
    parent_id="syn123456",
    scope_ids=["syn789012"],
    view_type_mask=ViewTypeMask.FILE
).store()

# Query the view like a table
view.get(include_columns=True)
```

### RecordSets
```python
from synapseclient.models import RecordSet

# Store a CSV as a RecordSet
record_set = RecordSet(
    name="metadata.csv",
    path="/path/to/metadata.csv",
    parent_id="syn123456"
).store()

# Get with validation results
record_set = RecordSet(id="syn789012").get()
validation_df = record_set.get_detailed_validation_results()
```

### Wiki Pages
```python
from synapseclient.models import WikiPage

# Create a wiki page for an entity
wiki = WikiPage(
    title="Project Documentation",
    owner_id="syn123456",
    markdown="# Overview\nThis project contains..."
).store()

# Get and update
wiki = WikiPage(id="12345", owner_id="syn123456").get()
wiki.markdown = "# Updated content"
wiki.store()

# Download attachments
wiki.get_attachment(file_name="figure.png", download_location="/downloads/")
```

### Provenance / Activity
```python
from synapseclient.models import File, Activity, UsedEntity, UsedURL

# Track data lineage
file = File(
    path="/path/to/result.csv",
    parent_id="syn123456",
    activity=Activity(
        name="Data Processing",
        description="Processed raw data",
        used=[
            UsedEntity(target_id="syn111", target_version_number=1),
            UsedEntity(target_id="syn222")
        ],
        executed=[
            UsedURL(name="Analysis Script", url="https://github.com/my/script")
        ]
    )
).store()
```

### Evaluations and Submissions
```python
from synapseclient.models import Evaluation

# Create an evaluation queue
evaluation = Evaluation(
    name="My Challenge",
    description="Challenge description",
    content_source="syn123456"
).store()

# Get evaluation
evaluation = Evaluation(id="12345").get()
```

### Synapse Agents (AI)
```python
from synapseclient.models import Agent, AgentSessionAccessLevel

# Register or retrieve an agent
agent = Agent(cloud_agent_id="your_agent_id").register()

# Start a session and prompt
session = agent.start_session(
    access_level=AgentSessionAccessLevel.PUBLICLY_ACCESSIBLE
)
response = agent.prompt("What files are in syn123456?", print_response=True)
print(response.response)
```

### Curation Tasks and Grid
```python
from synapseclient.models import (
    CurationTask, FileBasedMetadataTaskProperties, Grid
)

# Create a curation task
task = CurationTask(
    data_type="file",
    project_id="syn123456",
    instructions="Annotate tissue type",
    task_properties=FileBasedMetadataTaskProperties(
        upload_folder_id="syn789",
        file_view_id="syn456"
    )
).store()

# Work with Grid sessions
grid = Grid(record_set_id="syn999").create()
grid.import_csv(path="/path/to/data.csv")
grid.download_csv(destination="/output/")
grid.synchronize()  # Sync changes back
grid.export_to_record_set()
```

### Syncing Content
```python
from synapseclient.models import Project, Folder

# Sync entire project recursively
project = Project(id="syn123456")
project.sync_from_synapse(path="/local/path", recursive=True)

# Sync folder with specific entity types
folder = Folder(id="syn789012")
folder.sync_from_synapse(
    path="/local/path",
    include_types=["folder", "file"],
    download_file=True
)

# Upload from manifest CSV
project.sync_to_synapse(path="/local/project/", manifest_path="/path/to/manifest.csv")
```

### Download List
```python
from synapseclient.operations import download_list_files

# Bulk download files from your download list
download_list_files(download_location="/output/")
```

### Additional Operations
```python
from synapseclient.models import File

# Copy a file
new_file = File(id="syn123456").copy(parent_id="syn789012")

# Delete an entity
File(id="syn123456").delete()

# Move an entity
file = File(id="syn123456", download_file=False).get()
file.parent_id = "syn999999"
file.store()
```

## Operations Layer (Factory API)
```python
from synapseclient.operations import get, store, delete
from synapseclient.operations import FileOptions, ActivityOptions

# Get entity by ID with options
entity = get(
    synapse_id="syn123456",
    file_options=FileOptions(download_file=False),
    activity_options=ActivityOptions(include_activity=True)
)

# Store and delete
store(entity)
delete(entity)
```

## Available Models

| Model | Purpose |
|-------|---------|
| `Project` | Container for organizing work |
| `Folder` | Organize files within projects |
| `File` | Upload/download files with metadata |
| `Link` | Symbolic link to another entity |
| `Table` | Structured data with typed columns |
| `Dataset` | Curated collection of entity references |
| `DatasetCollection` | Collection of datasets |
| `EntityView` | Query-based view over entity metadata |
| `MaterializedView` | Materialized SQL view over tables |
| `VirtualTable` | Virtual SQL view (not materialized) |
| `SubmissionView` | View over evaluation submissions |
| `RecordSet` | CSV-backed structured data with validation |
| `Evaluation` | Challenge evaluation queues |
| `Submission` | Submission to an evaluation |
| `Team` | User groups with membership |
| `UserProfile` | User account information |
| `WikiPage` | Markdown documentation for entities |
| `DockerRepository` | Managed Docker images |
| `Agent` | Synapse AI agents |
| `CurationTask` | Data curation workflows |
| `Grid` | Interactive grid sessions for RecordSets |
| `Activity` | Provenance tracking |
| `Annotations` | Key-value metadata |
| `StorageLocation` | Custom storage configuration |
| `ProjectSetting` | Project-level settings |

## Best Practices
- Store auth tokens in `~/.synapseConfig` or `SYNAPSE_AUTH_TOKEN` env var, never hardcode
- Use `synapseclient.models` for all new code (not legacy `synapseclient.entity` classes)
- Use `.store()` for both create and update operations
- Use `download_file=False` when retrieving metadata only
- All annotation values must be lists (e.g., `{"key": ["value"]}`)
- For bulk parallel I/O, use async methods with `asyncio.gather()`
- On Python 3.14+, use `await method_async()` in async/notebook contexts

## Reference
- Main Docs: https://python-docs.synapse.org/
- API Reference: https://python-docs.synapse.org/reference/
- Authentication Guide: https://python-docs.synapse.org/tutorials/authentication/
