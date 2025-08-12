#!/usr/bin/env python3
"""
Continuous Integration Helper
Provides utilities for CI/CD pipeline
"""

import json
import time
import subprocess
from datetime import datetime
from pathlib import Path

class CIHelper:
    """Helper for CI/CD operations"""
    
    def __init__(self):
        self.start_time = time.time()
    
    def generate_build_info(self) -> dict:
        """Generate build information"""
        return {
            "build_timestamp": datetime.now().isoformat(),
            "git_commit": self._get_git_commit(),
            "git_branch": self._get_git_branch(),
            "build_number": self._get_build_number(),
            "python_version": self._get_python_version()
        }
    
    def _get_git_commit(self) -> str:
        """Get current git commit hash"""
        try:
            result = subprocess.run(["git", "rev-parse", "HEAD"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return "unknown"
    
    def _get_git_branch(self) -> str:
        """Get current git branch"""
        try:
            result = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return "unknown"
    
    def _get_build_number(self) -> str:
        """Get build number from environment or generate one"""
        import os
        return os.environ.get("BUILD_NUMBER", f"local-{int(time.time())}")
    
    def _get_python_version(self) -> str:
        """Get Python version"""
        import sys
        return f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    
    def create_deployment_package(self):
        """Create deployment package"""
        build_info = self.generate_build_info()
        
        # Save build info
        with open("build_info.json", 'w') as f:
            json.dump(build_info, f, indent=2)
        
        print(f"📦 Created deployment package:")
        print(f"  Commit: {build_info['git_commit'][:8]}")
        print(f"  Branch: {build_info['git_branch']}")
        print(f"  Build: {build_info['build_number']}")

if __name__ == "__main__":
    helper = CIHelper()
    helper.create_deployment_package()
