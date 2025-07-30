#!/bin/bash

# VSCode Integration Module
# Integrates smart autocompletion with VSCode

setup_vscode_extension() {
    local extension_dir="$1"
    
    echo "🔌 Setting up VSCode extension integration..."
    
    # Create extension manifest
    local package_json="$extension_dir/package.json"
    
    cat > "$package_json" << PACKAGE
{
  "name": "smart-context-autocompletion",
  "displayName": "Smart Context-Aware Autocompletion",
  "description": "Intelligent autocompletion with project awareness",
  "version": "1.0.0",
  "engines": {
    "vscode": "^1.60.0"
  },
  "categories": ["Other"],
  "activationEvents": [
    "onLanguage:swift"
  ],
  "main": "./out/extension.js",
  "contributes": {
    "commands": [
      {
        "command": "smartAutocompletion.analyze",
        "title": "Analyze Context"
      },
      {
        "command": "smartAutocompletion.suggest",
        "title": "Get Smart Suggestions"
      }
    ],
    "configuration": {
      "title": "Smart Autocompletion",
      "properties": {
        "smartAutocompletion.enabled": {
          "type": "boolean",
          "default": true,
          "description": "Enable smart autocompletion"
        },
        "smartAutocompletion.maxSuggestions": {
          "type": "number",
          "default": 10,
          "description": "Maximum number of suggestions"
        }
      }
    }
  },
  "scripts": {
    "compile": "tsc -p ./",
    "watch": "tsc -watch -p ./"
  },
  "devDependencies": {
    "@types/vscode": "^1.60.0",
    "typescript": "^4.0.0"
  }
}
PACKAGE
    
    # Create TypeScript extension code
    local extension_ts="$extension_dir/src/extension.ts"
    mkdir -p "$(dirname "$extension_ts")"
    
    cat > "$extension_ts" << TYPESCRIPT
import * as vscode from 'vscode';
import { exec } from 'child_process';
import * as path from 'path';

export function activate(context: vscode.ExtensionContext) {
    console.log('Smart Context-Aware Autocompletion activated');
    
    // Register completion provider
    const provider = vscode.languages.registerCompletionItemProvider(
        'swift',
        new SmartCompletionProvider(),
        '.'
    );
    
    context.subscriptions.push(provider);
    
    // Register commands
    const analyzeCommand = vscode.commands.registerCommand('smartAutocompletion.analyze', () => {
        analyzeCurrentContext();
    });
    
    const suggestCommand = vscode.commands.registerCommand('smartAutocompletion.suggest', () => {
        getSmartSuggestions();
    });
    
    context.subscriptions.push(analyzeCommand, suggestCommand);
}

class SmartCompletionProvider implements vscode.CompletionItemProvider {
    provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
        token: vscode.CancellationToken,
        context: vscode.CompletionContext
    ): Thenable<vscode.CompletionItem[]> {
        
        return new Promise((resolve, reject) => {
            const currentLine = document.lineAt(position.line).text;
            const currentWord = document.getText(document.getWordRangeAtPosition(position));
            
            // Call our smart autocompletion script
            const scriptPath = path.join(vscode.workspace.rootPath || '', '.automation_enhancements', 'smart_autocompletion', 'suggestion_engine.sh');
            
            exec(\`"\${scriptPath}" suggest "\${currentWord}" "\${document.fileName}" \${position.line} \${position.character}\`, 
                (error, stdout, stderr) => {
                    if (error) {
                        console.error('Autocompletion error:', error);
                        resolve([]);
                        return;
                    }
                    
                    try {
                        const suggestions = JSON.parse(stdout);
                        const completionItems = suggestions.suggestions.map((suggestion: any) => {
                            const item = new vscode.CompletionItem(suggestion.text, vscode.CompletionItemKind.Text);
                            item.detail = suggestion.description;
                            item.sortText = String(100 - suggestion.priority).padStart(3, '0');
                            return item;
                        });
                        
                        resolve(completionItems);
                    } catch (parseError) {
                        console.error('Failed to parse suggestions:', parseError);
                        resolve([]);
                    }
                }
            );
        });
    }
}

function analyzeCurrentContext() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showInformationMessage('No active editor');
        return;
    }
    
    const document = editor.document;
    const position = editor.selection.active;
    
    // Call context analyzer
    const scriptPath = path.join(vscode.workspace.rootPath || '', '.automation_enhancements', 'smart_autocompletion', 'context_analyzer.sh');
    
    exec(\`"\${scriptPath}" analyze "\${document.fileName}" \${position.line} \${position.character}\`, 
        (error, stdout, stderr) => {
            if (error) {
                vscode.window.showErrorMessage('Context analysis failed: ' + error.message);
                return;
            }
            
            vscode.window.showInformationMessage('Context analyzed successfully');
        }
    );
}

function getSmartSuggestions() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showInformationMessage('No active editor');
        return;
    }
    
    const document = editor.document;
    const position = editor.selection.active;
    const currentWord = document.getText(document.getWordRangeAtPosition(position)) || '';
    
    // Show quick pick with smart suggestions
    vscode.window.showQuickPick(['Analyzing...'], { placeHolder: 'Smart Suggestions' }).then(() => {
        // Implementation would show actual suggestions
        vscode.window.showInformationMessage('Smart suggestions feature activated');
    });
}

export function deactivate() {}
TYPESCRIPT
    
    echo "✅ VSCode extension integration configured"
}

create_vscode_settings() {
    local project_path="$1"
    
    echo "⚙️ Creating VSCode settings..."
    
    local vscode_dir="$project_path/.vscode"
    mkdir -p "$vscode_dir"
    
    # Create settings.json
    cat > "$vscode_dir/settings.json" << SETTINGS
{
    "smartAutocompletion.enabled": true,
    "smartAutocompletion.maxSuggestions": 10,
    "editor.quickSuggestions": {
        "other": true,
        "comments": false,
        "strings": false
    },
    "editor.quickSuggestionsDelay": 100,
    "editor.suggest.localityBonus": true,
    "editor.suggest.snippetsPreventQuickSuggestions": false
}
SETTINGS
    
    echo "✅ VSCode settings configured"
}

