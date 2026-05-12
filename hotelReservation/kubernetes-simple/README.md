# Hotel Reservation Kubernetes Simple Manifests

This folder contains plain Kubernetes YAML manifests for DeathStarBench Hotel Reservation.

The manifests are copied from the upstream hotelReservation/kubernetes folder and modified declaratively.

## Placement policy

Pinned to im-hp-10:

- mongodb-geo
- mongodb-profile
- mongodb-rate
- mongodb-recommendation
- mongodb-reservation
- mongodb-user
- memcached-profile
- memcached-rate
- memcached-reserve

PersistentVolumes are also pinned to im-hp-10 using PV node affinity.

Application services are not pinned and are left to the default Kubernetes scheduler:

- frontend
- geo
- profile
- rate
- recommendation
- reservation
- search
- user

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

## Rebuild simple manifests from upstream

python3 scripts/build_hotel_simple_manifests.py
