# 04 Database Schema + Data Dictionary + ER Diagram

## Entity Summary
| Entity | Purpose | Owner/Source |
|---|---|---|
|  |  |  |

## Table: table_name
| Field | Type | Nullable | Key | Default | Description |
|---|---|---|---|---|---|
| id | bigint | No | PK | auto | Unique record identifier |
| created_at | timestamp | No |  | current_timestamp | Record creation date/time |
| updated_at | timestamp | Yes |  |  | Last update date/time |

## Indexes
| Table | Index | Fields | Unique | Purpose |
|---|---|---|---|---|
|  |  |  | Yes/No |  |

## Relationships
| From Table | Field | To Table | Field | Relationship | Description |
|---|---|---|---|---|---|
|  |  |  |  | 1:N |  |

## ER Diagram
```mermaid
erDiagram
  SAMPLE ||--o{ SAMPLE_DETAIL : has
  SAMPLE {
    bigint id "Unique record identifier"
    string name "Display name"
    datetime created_at "Record creation date/time"
  }
  SAMPLE_DETAIL {
    bigint id "Unique detail identifier"
    bigint sample_id "Reference to sample"
  }
```

## Data Retention
- 

## Migration Notes
- 

