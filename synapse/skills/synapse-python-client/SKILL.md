---
name: synapse-python-client
description: Use when writing code that interacts with Synapse (synapse.org) — uploads/downloads, table queries, projects/folders, provenance. Uses the modern synapseclient.models API.
---

# Synapse Python Client Skill

## Overview
The Synapse Python client (`synapseclient`) is used to interact with Synapse (synapse.org), a collaborative platform for biomedical data sharing.

**Note**: This skill uses the modern experimental interfaces (`synapseclient.models`) which represent the future direction of the client. These interfaces provide a cleaner, more Pythonic API.

## Installation
```bash
pip install synapseclient
```

## Authentication
```python
import synapseclient

# Using personal access token (required)
synapseclient.login(authToken="your_token")

# Or store token in ~/.synapseConfig with [default] profile
synapseclient.login()

# Or use environment variable SYNAPSE_AUTH_TOKEN
synapseclient.login()
```

**Note**: All authentication methods require a Personal Access Token from synapse.org Settings.

## Core Concepts
- **Entity**: Base class for Synapse objects (Projects, Folders, Files, Tables)
- **Synapse ID**: Format `syn123456` — unique identifier for every entity
- **Provenance**: Track data lineage via Activity objects

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
# file.path → local path to downloaded file

# Download to specific directory
file = File(id="syn123456", path="/download/directory").get()

# Get metadata only (no download)
file = File(id="syn123456", download_file=False).get()
```

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
    parent_id=project.id,
    description="Folder description"
).store()

# Retrieve project/folder metadata
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

### Syncing Content Locally
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
```

### Additional Operations
```python
from synapseclient.models import File, Folder

# Copy a file to a new location
new_file = File(id="syn123456").copy(parent_id="syn789012")

# Delete an entity
File(id="syn123456").delete()

# Move an entity
file = File(id="syn123456", download_file=False).get()
file.parent_id = "syn999999"
file.store()
```

## Best Practices
- Store auth tokens in `~/.synapseConfig` or environment variable `SYNAPSE_AUTH_TOKEN`, never hardcode
- Use the experimental interfaces (`synapseclient.models`) for new code
- Use `.store()` for both create and update operations
- Use `download_file=False` when retrieving metadata only to avoid unnecessary downloads
- Annotations support multiple data types: strings, integers, floats, booleans, dates, datetimes
- All annotations values must be lists (e.g., `{"key": ["value"]}`)

## Reference
- Main Docs: https://python-docs.synapse.org/en/stable/
- File Operations: https://python-docs.synapse.org/en/stable/reference/experimental/sync/file/
- Authentication Guide: https://python-docs.synapse.org/en/stable/tutorials/authentication/
