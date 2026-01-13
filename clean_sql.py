import re

def clean_sql(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by semicolon to get statements (rough approximation)
    # This might split inside strings, but for this specific file structure it's likely fine.
    # A better way is to regex match specific known DDL patterns.
    
    # Actually, let's just keep blocks that start with CREATE or ALTER.
    # And maybe specialized SET or COMMENT.
    
    # We will iterate line by line, but track if we are inside a "skippable" block.
    # Since SQL statements end with ;, we can skip until ; if we find a bad start keyword.
    
    lines = content.split('\n')
    cleaned_lines = []
    
    skip_mode = False
    
    # Keywords that start a statement we want to REMOVE
    # We keep CREATE, ALTER, CONSTRAINT, COMMENT
    bad_starts = ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SELECT', 'WITH', 'BEGIN', 'DROP', 'COPY')
    
    current_statement = []
    
    for line in lines:
        stripped = line.strip()
        
        # If empty line, valid to keep (formatting)
        if not stripped:
            if not skip_mode:
                cleaned_lines.append(line)
            continue
            
        # Check start of statement (if we are not currently skipping or inside a statement)
        # This simple logic assumes statements don't start in the middle of a line after another statement,
        # which is true for this file.
        
        upper = stripped.upper()
        
        # If we are not skipping, we check if this line starts a bad block
        if not skip_mode:
            is_bad = False
            for bad in bad_starts:
                if upper.startswith(bad):
                    is_bad = True
                    break
            
            if is_bad:
                skip_mode = True
                # Check if it ends on same line
                if stripped.endswith(';'):
                    skip_mode = False
                continue
            else:
                # Good line (DDL or comment)
                cleaned_lines.append(line)
        else:
            # We are in skip mode, check if this line ends the statement
            if stripped.endswith(';'):
                skip_mode = False
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(cleaned_lines))

if __name__ == '__main__':
    clean_sql('paw_rescue_data1/schema_visual_paradigm.sql', 'paw_rescue_data1/schema_er_clean.sql')
    print("Cleaned SQL file created.")
