import { PrismaClient } from "@prisma/client";
import { hash } from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  let r1 = await prisma.busRoute.findFirst({ where: { id: "seed_route_dsc" } });
  if (!r1) {
    r1 = await prisma.busRoute.create({
      data: {
        id: "seed_route_dsc",
        name: "Uttara — DSC",
        code: "UTT-DSC",
        normalizedName: "uttara-dsc",
      },
    });
  }
  let r2 = await prisma.busRoute.findFirst({ where: { id: "seed_route_du" } });
  if (!r2) {
    r2 = await prisma.busRoute.create({
      data: {
        id: "seed_route_du",
        name: "Uttara — DU",
        code: "UTT-DU",
        normalizedName: "uttara-du",
      },
    });
  }

  let b1 = await prisma.bus.findUnique({ where: { code: "SM-101" } });
  if (!b1) b1 = await prisma.bus.create({ data: { code: "SM-101" } });
  let b2 = await prisma.bus.findUnique({ where: { code: "SM-104" } });
  if (!b2) b2 = await prisma.bus.create({ data: { code: "SM-104" } });

  const count = await prisma.schedule.count();
  if (count === 0) {
    await prisma.schedule.createMany({
      data: [
        {
          routeId: r1.id,
          busId: b1.id,
          weekday: 0,
          timeLabel: "7.00 AM",
          dateLabel: "12 May",
          origin: "Rajhlokkhi",
          universityTags: ["DSC", "Dhaka", "Uttara"],
        },
        {
          routeId: r1.id,
          busId: b2.id,
          weekday: 0,
          timeLabel: "8.30 AM",
          dateLabel: "12 May",
          origin: "Rajhlokkhi",
          universityTags: ["DSC", "Dhaka"],
        },
        {
          routeId: r2.id,
          busId: b1.id,
          weekday: 1,
          timeLabel: "7.15 AM",
          dateLabel: "13 May",
          origin: "Uttara",
          universityTags: ["DU"],
        },
      ],
    });
  }

  const userCount = await prisma.appUser.count();
  if (userCount === 0) {
    await prisma.appUser.createMany({
      data: [
        {
          fullName: "Monie Islam",
          email: "monie@studentmove.edu",
          phone: "01700000001",
          studentId: "221-15-1001",
          department: "CSE",
          role: "SUPER_ADMIN",
          isActive: true,
        },
        {
          fullName: "Surjomokhi Rahman",
          email: "surjomokhi@studentmove.edu",
          phone: "01700000002",
          studentId: "221-15-1002",
          department: "EEE",
          role: "TRANSPORT_ADMIN",
          isActive: true,
        },
      ],
    });
  }

  const adminCount = await prisma.adminAccount.count();
  if (adminCount === 0) {
    const superEmail = (
      process.env.ADMIN_SEED_SUPER_EMAIL || "admin@studentmove.local"
    )
      .trim()
      .toLowerCase();
    const superPassword = (
      process.env.ADMIN_SEED_SUPER_PASSWORD || "admin12345"
    ).trim();
    const transportEmail = (
      process.env.ADMIN_SEED_TRANSPORT_EMAIL || "transport@studentmove.local"
    )
      .trim()
      .toLowerCase();
    const transportPassword = (
      process.env.ADMIN_SEED_TRANSPORT_PASSWORD || "transport12345"
    ).trim();

    await prisma.adminAccount.createMany({
      data: [
        {
          email: superEmail,
          passwordHash: await hash(superPassword, 12),
          role: "SUPER_ADMIN",
          isActive: true,
        },
        {
          email: transportEmail,
          passwordHash: await hash(transportPassword, 12),
          role: "TRANSPORT_ADMIN",
          isActive: true,
        },
      ],
    });
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch((e) => {
    console.error(e);
    prisma.$disconnect();
    process.exit(1);
  });
