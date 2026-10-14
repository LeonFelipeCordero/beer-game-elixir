# Beer Game

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Assumption, delegated by the owner: students and workshop participants learning systems thinking together, with an organizer creating the board. No specific age or institutional audience is confirmed.

## Product Purpose

A multiplayer beer supply-chain simulation that helps participants understand delays, interdependence, and feedback loops through their own inventory and ordering decisions.

## Operating Context

Players create or join a named board, select an available role, then operate their own part of the supply chain. Roles are retailer, wholesaler, and factory. Players cannot directly communicate through the game; limited visibility and delayed feedback are intentional.

## Capabilities and Constraints

Phoenix LiveView web app with PostgreSQL persistence. Preserve the existing join, create-board, board-list, role-selection, and gameplay routes and funnels. Preserve stock, last order, weekly order/production, incoming/outgoing orders, delivery availability, board deletion, and quitting. Keep server events, sessions, timing, and game logic unchanged. Do not add cross-role visibility, chat, scores, round controls, or invented game data.

## Brand Commitments

Name: Beer Game. The owner requested a complete visual redesign with a consistent theme across all existing screens and delegated design judgment. Friendly strategy-game positioning is a design assumption, not a new product claim.

## Evidence on Hand

Existing LiveView templates and game schemas are the functionality authority. README describes the educational purpose, three roles, and intended systems-thinking outcomes. No customer claims, testimonials, or game performance benchmarks exist.

## Product Principles

Teach through decisions, not invented metrics. Keep each role's information boundaries intact. Make available actions and waiting states legible. Preserve the existing funnels while making the whole game feel like one coherent experience.
