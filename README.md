# DeathStarBench Hotel Reservation Kubernetes Deployment

This repository contains a simplified Kubernetes deployment of the DeathStarBench Hotel Reservation benchmark.

The deployment is adapted for a Kubernetes cluster where:

- MongoDB services run on im-hp-10
- Memcached services run on im-hp-10
- PersistentVolumes are pinned to im-hp-10
- Application services are left to the default Kubernetes scheduler

## Main manifest folder

The main deployable manifests are in:

hotelReservation/kubernetes-simple/

## Deploy

cd ~/DeathStarBench
kubectl apply -f hotelReservation/kubernetes-simple/

## Verify pods

kubectl get pods -n hotel-res -o wide

## Verify PVC/PV binding

kubectl get pvc -n hotel-res
kubectl get pv | egrep 'geo|profile|rate|recommendation|reservation|user'

## Verify DB and cache placement

kubectl get pods -n hotel-res -o wide | egrep 'mongodb|memcached'

Expected: all MongoDB and memcached pods should run on im-hp-10.

## Port forward frontend

kubectl -n hotel-res port-forward --address 0.0.0.0 svc/frontend 5000:5000

## Smoke test

curl -I http://127.0.0.1:5000

curl -s "http://127.0.0.1:5000/hotels?inDate=2015-04-09&outDate=2015-04-10&lat=37.7749&lon=-122.4194" | head

## Clean deployment

kubectl delete namespace hotel-res --ignore-not-found --wait=true

kubectl delete pv geo-pv profile-pv rate-pv recommendation-pv reservation-pv user-pv --ignore-not-found

## Rebuild simple manifests

python3 scripts/build_hotel_simple_manifests.py
