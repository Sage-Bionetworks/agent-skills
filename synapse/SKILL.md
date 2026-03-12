# Synapse Python Client Skill

## Overview
The Synapse Python client (`synapseclient`) is used to interact with Synapse (synapse.org), a collaborative platform for biomedical data sharing.

## Installation
```bash
pip install synapseclient
```

## Authentication
```python
import synapseclient
syn = synapseclient.Synapse()
syn.login(authToken="your_token")  # Preferred: use personal access token
# Or via ~/.synapseConfig file
```

## Core Concepts
- **Entity**: Base class for Synapse objects (Projects, Folders, Files, Tables)
- **Synapse ID**: Format `syn123456` — unique identifier for every entity
- **Provenance**: Track data lineage via Activity objects

## Common Operations

### Upload a File
```python
file = synapseclient.File(path="/local/path/file.csv", parent="syn123456")
file = syn.store(file)
print(file.id)  # syn ID of uploaded file
```

### Download a File
```python
entity = syn.get("syn123456")
# entity.path → local path to downloaded file
```

### Working with Tables
```python
import pandas as pd
results = syn.tableQuery("SELECT * FROM syn123456")
df = results.asDataFrame()

# Upload table
schema = syn.get("syn123456")  # existing table
table = synapseclient.Table(schema, df)
syn.store(table)
```

### Projects and Folders
```python
project = synapseclient.Project("My Project")
project = syn.store(project)

folder = synapseclient.Folder("Data", parent=project)
folder = syn.store(folder)
```

### Annotations
```python
entity = syn.get("syn123456")
entity.annotations = {"tissue": "brain", "assay": "RNAseq"}
syn.store(entity)
```

### Provenance / Activity
```python
activity = synapseclient.Activity(
    name="Data Processing",
    used=["syn111", "syn222"],
    executed="https://github.com/my/script"
)
file = syn.store(file, activity=activity)
```

### Permissions / ACLs
```python
syn.setPermissions("syn123456", principalId=12345, accessType=["READ", "DOWNLOAD"])
```

### Async / Large Transfers
- Use `syn.get()` with `downloadFile=False` to get metadata only
- Multi-threaded uploads happen automatically for large files

## Best Practices
- Store auth tokens in `~/.synapseConfig` or environment variables, never hardcode
- Use `syn.store()` for both create and update operations
- Check entity type with `isinstance(entity, synapseclient.File)`
- Use `syn.getChildren("syn123456")` to list folder contents

## Reference
- Docs: https://python-docs.synapse.org/en/stable/
- API Reference: https://python-docs.synapse.org/en/stable/reference/
