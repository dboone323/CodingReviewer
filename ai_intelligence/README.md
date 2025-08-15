# AI Excellence System Maintenance Guide

## Quick Status Check

To check the current status of the AI Excellence System:

```bash
# Run health check
python3 ai_intelligence/ai_system_health_check.py

# Run monitoring script  
bash ai_intelligence/ai_system_monitor.sh
```

## Common Issues and Solutions

### Issue: Neural Networks Not Working
**Symptoms**: ImportError for numpy, pandas, or other ML libraries
**Solution**: 
```bash
pip install -r requirements.txt
```

### Issue: AI System Alert Generated
**Symptoms**: Alert files in `ai_data/alerts/`
**Solution**:
1. Run health check to identify specific issue
2. Check system status: `cat ai_data/system_status.json`
3. Verify dependencies are installed
4. Test individual components

## System Components

### Neural Networks
- **Performance Predictor**: `ai_intelligence/neural_networks/performance_predictor.py`
- **Code Quality AI**: `ai_intelligence/neural_networks/code_quality_ai.py`

### Autonomous Systems  
- **Optimization Engine**: `ai_intelligence/autonomous_systems/optimization_engine.sh`

### Monitoring
- **Health Check**: `ai_intelligence/ai_system_health_check.py`
- **System Monitor**: `ai_intelligence/ai_system_monitor.sh`

## Data Directories

- `ai_data/model_outputs/`: Neural network analysis results
- `ai_data/optimization_history/`: Optimization cycle logs
- `ai_data/performance_baselines/`: Performance metrics
- `ai_data/ml_models/`: Machine learning model updates
- `ai_data/health_reports/`: System health check reports
- `ai_data/alerts/`: System alerts and issues

## Expected Status

When working properly, you should see:
- ✅ All dependencies installed
- ✅ Neural networks operational (91%+ confidence)  
- ✅ Autonomous systems active
- ✅ Recent files in all ai_data directories
- ✅ System status: "operational"

## Troubleshooting

1. **Dependencies**: Install missing packages with `pip install -r requirements.txt`
2. **Permissions**: Ensure scripts are executable with `chmod +x`
3. **Python Path**: Ensure you're in the repository root directory
4. **System Resources**: AI components may need adequate memory/CPU

## Emergency Recovery

If the AI system is completely non-functional:

```bash
# 1. Install all dependencies
pip install -r requirements.txt

# 2. Test neural networks
python3 ai_intelligence/neural_networks/performance_predictor.py

# 3. Test autonomous systems
bash ai_intelligence/autonomous_systems/optimization_engine.sh

# 4. Run full health check
python3 ai_intelligence/ai_system_health_check.py
```

## Contact

For persistent issues, check:
- AI configuration: `ai_intelligence/ai_config.json`
- System logs in `ai_data/` directories
- Health reports in `ai_data/health_reports/`