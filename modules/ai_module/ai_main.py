#!/usr/bin/env python3
"""
UWP AI Module - Main AI functionality
"""

import sys
import json
import os
from pathlib import Path

class UWP_AI:
    """Main AI class for UWP"""
    
    def __init__(self):
        self.config_path = os.path.join(
            os.path.expanduser("~"),
            ".universal-workspace",
            "configs",
            "ai_config.json"
        )
        self.config = self.load_config()
        
    def load_config(self):
        """Load AI configuration"""
        default_config = {
            "model": "local",
            "language": "cz",
            "max_tokens": 1024,
            "temperature": 0.7,
            "offline_mode": True
        }
        
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    return json.load(f)
            else:
                return default_config
        except:
            return default_config
    
    def save_config(self):
        """Save AI configuration"""
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def process_input(self, text):
        """Process input text"""
        if self.config["offline_mode"]:
            return self.offline_process(text)
        else:
            return self.online_process(text)
    
    def offline_process(self, text):
        """Offline text processing"""
        responses = {
            "ahoj": "Ahoj! Jsem UWP AI modul. Jak mohu pomoci?",
            "help": "Dostupné příkazy: status, config, chat, exit",
            "status": f"UWP AI Status:\n- Model: {self.config['model']}\n- Jazyk: {self.config['language']}\n- Offline: {self.config['offline_mode']}",
            "config": f"Aktuální konfigurace: {json.dumps(self.config, indent=2, ensure_ascii=False)}"
        }
        
        text_lower = text.lower().strip()
        return responses.get(text_lower, f"Zpracováno offline: {text}")
    
    def online_process(self, text):
        """Online text processing (placeholder)"""
        return f"Online mód není implementován. Text: {text}"
    
    def interactive_chat(self):
        """Interactive chat mode"""
        print("=" * 50)
        print("UWP AI MODUL - Interaktivní režim")
        print("Napište 'exit' pro ukončení")
        print("=" * 50)
        
        while True:
            try:
                user_input = input("\nTy: ")
                
                if user_input.lower() in ['exit', 'quit', 'q']:
                    print("Ukončuji chat...")
                    break
                
                response = self.process_input(user_input)
                print(f"AI: {response}")
                
            except KeyboardInterrupt:
                print("\n\nUkončeno uživatelem")
                break
            except Exception as e:
                print(f"Chyba: {e}")

def main():
    """Main function"""
    ai = UWP_AI()
    
    if len(sys.argv) > 1:
        # Command line mode
        if sys.argv[1] == "--chat":
            ai.interactive_chat()
        elif sys.argv[1] == "--config":
            print(json.dumps(ai.config, indent=2, ensure_ascii=False))
        elif sys.argv[1] == "--status":
            print(ai.process_input("status"))
        else:
            # Process single input
            result = ai.process_input(" ".join(sys.argv[1:]))
            print(result)
    else:
        # Interactive mode
        ai.interactive_chat()

if __name__ == "__main__":
    main()
