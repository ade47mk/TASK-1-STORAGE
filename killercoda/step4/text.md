# Step 4: Verify and Test Persistence

The final step is to verify that your persistent volume actually persists data across Pod restarts!

## 📝 Write Test Data

First, write some data to the persistent volume:

```bash
kubectl exec app-pod -- sh -c "echo 'Data written at $(date)' > /data/persistence-test.txt"
```

Verify the file exists:

```bash
kubectl exec app-pod -- cat /data/persistence-test.txt
```

## 🔄 Test Persistence

Now let's test if the data persists when the Pod is deleted and recreated:

1. **Delete the Pod**:
   ```bash
   kubectl delete pod app-pod
   ```

2. **Recreate the Pod**:
   ```bash
   kubectl apply -f manifests/pod.yaml
   ```

3. **Wait for the Pod to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod/app-pod --timeout=60s
   ```

4. **Check if the data still exists**:
   ```bash
   kubectl exec app-pod -- cat /data/persistence-test.txt
   ```

If you can still read the file, congratulations! Your persistent volume is working correctly.

## 🎯 Run Full Verification

Run the comprehensive verification script:

```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

This script will check:
- ✅ PVC exists with correct specifications
- ✅ PVC is bound to a PersistentVolume
- ✅ Pod is running
- ✅ Volume is mounted at `/data`
- ✅ Volume is readable and writable

## 🧹 Cleanup (Optional)

When you're done, you can clean up all resources:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

Great job completing the exam! 🎉
